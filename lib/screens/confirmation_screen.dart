import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/notification_store.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ConfirmationScreen extends StatefulWidget {
  final SportVenue venue;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String courtType;
  final String price;

  const ConfirmationScreen({
    super.key,
    required this.venue,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.courtType,
    required this.price,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isConfirmed = false;
  int _selectedPayment = 0;
  String _bookingCode = '';
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _prefillFromAuth();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
  }

  Future<void> _prefillFromAuth() async {
    final phone = AuthService.currentPhone;
    if (phone != null) _phoneController.text = phone;
    final name = await AuthService.getUserName();
    if (name != null && mounted) _nameController.text = name;
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      '1-р сар',
      '2-р сар',
      '3-р сар',
      '4-р сар',
      '5-р сар',
      '6-р сар',
      '7-р сар',
      '8-р сар',
      '9-р сар',
      '10-р сар',
      '11-р сар',
      '12-р сар',
    ];
    const weekDays = [
      'Даваа',
      'Мягмар',
      'Лхагва',
      'Пүрэв',
      'Баасан',
      'Бямба',
      'Ням',
    ];
    return '${weekDays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  Future<void> _confirm() async {
    FocusScope.of(context).unfocus();
    final phone = _phoneController.text.replaceAll(RegExp(r'[\s\-]'), '');
    String? error;
    if (_nameController.text.trim().isEmpty) {
      error = 'Нэрээ оруулна уу';
    } else if (phone.isEmpty) {
      error = 'Утасны дугаараа оруулна уу';
    } else if (!RegExp(r'^\d{8}$').hasMatch(phone)) {
      error = 'Утасны дугаар 8 оронтой байх ёстой';
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.replaceAll(RegExp(r'[\s\-]'), '');

      // Хэрэглэгч бүртгэх / шинэчлэх
      await ApiService.registerUser(name: name, phone: phone);

      // Захиалга үүсгэх (давхцал server-т шалгана)
      final result = await ApiService.createBooking(
        venueId: widget.venue.id,
        venueName: widget.venue.name,
        venueType: widget.venue.type,
        venueLocation: widget.venue.location,
        venueAccentColor: widget.venue.accentColor.toARGB32(),
        date: widget.date,
        timeSlot: widget.startTime,
        timeSlotEnd: widget.endTime,
        courtType: widget.courtType,
        price: widget.price,
        userName: name,
        userPhone: phone,
      );
      _bookingCode = result.code;
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    NotificationStore.instance.add(AppNotification(
      id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
      type: AppNotificationType.booking,
      title: 'Захиалга баталгаажлаа',
      body:
          '${widget.venue.name} — ${widget.courtType}, ${widget.date.month}-р сарын ${widget.date.day}, '
          '${widget.startTime}–${widget.endTime}',
      createdAt: DateTime.now(),
    ));

    NotificationStore.instance.add(AppNotification(
      id: 'reminder_${DateTime.now().millisecondsSinceEpoch}',
      type: AppNotificationType.reminder,
      title: 'Сануулга тохируулагдлаа',
      body:
          '${widget.venue.name} заалд очихоос 1 цагийн өмнө сануулга ирнэ.',
      createdAt: DateTime.now(),
    ));

    setState(() {
      _isLoading = false;
      _isConfirmed = true;
    });
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_isConfirmed) {
      return _buildSuccessScreen();
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Захиалга баталгаажуулах'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.venue.accentColor.withValues(alpha: 0.2),
                    AppTheme.cardColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.venue.accentColor.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: widget.venue.accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getIcon(widget.venue.type),
                          color: widget.venue.accentColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.venue.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              widget.venue.type,
                              style: TextStyle(
                                color: widget.venue.accentColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppTheme.divider),
                  const SizedBox(height: 16),
                  _BookingDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Огноо',
                    value: _formatDate(widget.date),
                    color: widget.venue.accentColor,
                  ),
                  const SizedBox(height: 14),
                  _BookingDetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Цаг',
                    value: '${widget.startTime} – ${widget.endTime}',
                    color: widget.venue.accentColor,
                  ),
                  const SizedBox(height: 14),
                  _BookingDetailRow(
                    icon: Icons.crop_square_rounded,
                    label: 'Талбайн төрөл',
                    value: widget.courtType,
                    color: widget.venue.accentColor,
                  ),
                  const SizedBox(height: 14),
                  _BookingDetailRow(
                    icon: Icons.location_on_rounded,
                    label: 'Байршил',
                    value: widget.venue.location,
                    color: widget.venue.accentColor,
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppTheme.divider),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Нийт төлбөр',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.price,
                        style: TextStyle(
                          color: widget.venue.accentColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Таны мэдээлэл',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            // Name field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Нэр',
                hintText: 'Таны нэр',
                prefixIcon: Icon(
                  Icons.person_rounded,
                  color: widget.venue.accentColor,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Phone field — auth-аас автоматаар дүүргэгддэг
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              readOnly: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Утасны дугаар',
                hintText: '9999-9999',
                prefixIcon: Icon(
                  Icons.phone_rounded,
                  color: widget.venue.accentColor,
                ),
                suffixIcon: const Icon(Icons.lock_rounded,
                    color: AppTheme.textSecondary, size: 16),
              ),
            ),

            const SizedBox(height: 28),

            // Payment method
            const Text(
              'Төлбөрийн хэлбэр',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _PaymentOption(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'QPay',
                  isSelected: _selectedPayment == 0,
                  color: widget.venue.accentColor,
                  onTap: () => setState(() => _selectedPayment = 0),
                ),
                const SizedBox(width: 12),
                _PaymentOption(
                  icon: Icons.credit_card_rounded,
                  label: 'Карт',
                  isSelected: _selectedPayment == 1,
                  color: widget.venue.accentColor,
                  onTap: () => setState(() => _selectedPayment = 1),
                ),
                const SizedBox(width: 12),
                _PaymentOption(
                  icon: Icons.money_rounded,
                  label: 'Бэлэн',
                  isSelected: _selectedPayment == 2,
                  color: widget.venue.accentColor,
                  onTap: () => setState(() => _selectedPayment = 2),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.divider)),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.venue.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : const Text(
                      'Захиалга баталгаажуулах',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        widget.venue.accentColor.withValues(alpha: 0.3),
                        widget.venue.accentColor.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.venue.accentColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: widget.venue.accentColor,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Захиалга\nАмжилттай!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Таны захиалга баталгаажлаа.\nУтасны дугаарт мэдэгдэл илгээнэ.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // Booking reference
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.venue.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatDate(widget.date)} • ${widget.startTime}–${widget.endTime}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: widget.venue.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.venue.accentColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Захиалгын дугаар',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.confirmation_number_rounded,
                                color: widget.venue.accentColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _bookingCode,
                                style: TextStyle(
                                  color: widget.venue.accentColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.venue.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Нүүр хуудас руу буцах',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    // Navigate to bookings tab (index 1)
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: widget.venue.accentColor.withValues(alpha: 0.4),
                    ),
                    foregroundColor: widget.venue.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Захиалгуудаа харах',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'Сагсан бөмбөг':
        return Icons.sports_basketball_rounded;
      case 'Волейбол':
        return Icons.sports_volleyball_rounded;
      default:
        return Icons.sports_rounded;
    }
  }
}

class _BookingDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _BookingDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppTheme.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppTheme.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
