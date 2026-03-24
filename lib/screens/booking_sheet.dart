import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'confirmation_screen.dart';
import 'auth/login_screen.dart';

void showBookingSheet(BuildContext context, SportVenue venue) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BookingSheet(venue: venue),
  );
}

class _BookingSheet extends StatefulWidget {
  final SportVenue venue;
  const _BookingSheet({required this.venue});

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  DateTime _selectedDate = DateTime.now();
  List<TimeSlot> _timeSlots = [];
  List<TimeSlot> _selectedSlots = [];
  bool _isFullCourt = true;
  bool _isLoadingSlots = false;

  static const _weekDays = ['Да', 'Мя', 'Лх', 'Пү', 'Ба', 'Бя', 'Ня'];

  int get _basePrice =>
      int.tryParse(widget.venue.pricePerHour.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

  int get _pricePerHour => _isFullCourt ? _basePrice : (_basePrice / 2).round();

  String _formatPrice(int p) {
    if (p >= 1000) {
      final thousands = p ~/ 1000;
      final remainder = p % 1000;
      if (remainder == 0) return '$thousands,000₮';
      return '$thousands,${remainder.toString().padLeft(3, '0')}₮';
    }
    return '$p₮';
  }

  String get _priceLabel => _formatPrice(_pricePerHour);
  String get _halfPriceLabel => _formatPrice((_basePrice / 2).round());
  String get _totalPriceLabel =>
      _formatPrice(_pricePerHour * (_selectedSlots.isEmpty ? 1 : _selectedSlots.length));

  @override
  void initState() {
    super.initState();
    _loadSlots(_selectedDate);
  }

  Future<void> _loadSlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _selectedSlots = [];
    });
    try {
      final slots = await ApiService.getSchedule(widget.venue.id, date);
      if (mounted) setState(() => _timeSlots = slots);
    } catch (_) {
      // API-д холбогдохгүй бол hardcode fallback ашиглана
      if (mounted) {
        setState(() => _timeSlots = AppData.generateTimeSlots(widget.venue.id, date));
      }
    } finally {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  void _clearSlotSelection() {
    for (final s in _timeSlots) { s.isSelected = false; }
    _selectedSlots = [];
  }

  void _selectSlot(TimeSlot slot) {
    if (slot.isBooked || slot.isFixed) return;
    setState(() {
      if (_selectedSlots.isEmpty) {
        slot.isSelected = true;
        _selectedSlots = [slot];
        return;
      }
      // Already selected → deselect all
      if (_selectedSlots.contains(slot)) {
        _clearSlotSelection();
        return;
      }
      final tapIdx   = _timeSlots.indexOf(slot);
      final firstIdx = _timeSlots.indexOf(_selectedSlots.first);
      final lastIdx  = _timeSlots.indexOf(_selectedSlots.last);

      if (tapIdx == lastIdx + 1) {
        // Дараагийн зэрэгцээ цаг — урагш өргөтгөх
        slot.isSelected = true;
        _selectedSlots.add(slot);
      } else if (tapIdx == firstIdx - 1) {
        // Өмнөх зэрэгцээ цаг — хойш өргөтгөх
        slot.isSelected = true;
        _selectedSlots.insert(0, slot);
      } else {
        // Зэрэгцээ биш — шинэ сонголт эхлүүлэх
        _clearSlotSelection();
        slot.isSelected = true;
        _selectedSlots = [slot];
      }
    });
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'Сагсан бөмбөг': return Icons.sports_basketball_rounded;
      case 'Волейбол':       return Icons.sports_volleyball_rounded;
      default:               return Icons.sports_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top:   BorderSide(color: AppTheme.divider),
              left:  BorderSide(color: AppTheme.divider),
              right: BorderSide(color: AppTheme.divider),
            ),
          ),
          child: Column(
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // ── Venue header ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: widget.venue.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: widget.venue.accentColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        _getIcon(widget.venue.type),
                        color: widget.venue.accentColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.venue.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: AppTheme.textSecondary,
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  widget.venue.location,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _priceLabel,
                          style: TextStyle(
                            color: widget.venue.accentColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          '/ цаг',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(color: AppTheme.divider, height: 1),

              // ── Scrollable content ───────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
                  children: [
                    // Court type selector
                    const Text(
                      'Талбайн төрөл',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _CourtTypeCard(
                          label: 'Бүтэн талбай',
                          description: '${widget.venue.pricePerHour} / цаг',
                          icon: Icons.crop_square_rounded,
                          isSelected: _isFullCourt,
                          accentColor: widget.venue.accentColor,
                          onTap: () => setState(() => _isFullCourt = true),
                        ),
                        const SizedBox(width: 10),
                        _CourtTypeCard(
                          label: 'Хагас талбай',
                          description: '$_halfPriceLabel / цаг',
                          icon: Icons.vertical_split_rounded,
                          isSelected: !_isFullCourt,
                          accentColor: widget.venue.accentColor,
                          onTap: () => setState(() => _isFullCourt = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Date picker
                    const Text(
                      'Өдөр сонгох',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 14,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final date = DateTime.now().add(Duration(days: i));
                          final isSelected =
                              _selectedDate.day == date.day &&
                              _selectedDate.month == date.month;

                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedDate = date);
                              _loadSlots(date);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 50,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? widget.venue.accentColor
                                    : AppTheme.cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? widget.venue.accentColor
                                      : AppTheme.divider,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _weekDays[date.weekday - 1],
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : AppTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : AppTheme.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Time slot header + legend
                    Row(
                      children: [
                        const Text(
                          'Цаг сонгох',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        _dot(const Color(0xFF8B5CF6)),
                        const SizedBox(width: 5),
                        const Text('Гэрээт',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11)),
                        const SizedBox(width: 10),
                        _dot(AppTheme.divider),
                        const SizedBox(width: 5),
                        const Text('Захиалагдсан',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11)),
                        const SizedBox(width: 10),
                        _dot(widget.venue.accentColor),
                        const SizedBox(width: 5),
                        const Text('Сонгосон',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Instruction text
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            color: widget.venue.accentColor,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Доорх цагуудаас нэгийг дарж сонгоно уу',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Time slot grid
                    if (_isLoadingSlots)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.7,
                      ),
                      itemCount: _timeSlots.length,
                      itemBuilder: (context, i) => TimeSlotChip(
                        slot: _timeSlots[i],
                        onTap: () => _selectSlot(_timeSlots[i]),
                        accentColor: widget.venue.accentColor,
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),

              // ── Bottom action bar ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(top: BorderSide(color: AppTheme.divider)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedSlots.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: widget.venue.accentColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.venue.accentColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event_rounded,
                                  color: widget.venue.accentColor, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_selectedDate.month}-р сарын ${_selectedDate.day}, '
                                      '${_selectedSlots.first.time}–${_selectedSlots.last.endTime}',
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${_isFullCourt ? 'Бүтэн талбай' : 'Хагас талбай'} • ${_selectedSlots.length} цаг',
                                      style: TextStyle(
                                        color: widget.venue.accentColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _totalPriceLabel,
                                style: TextStyle(
                                  color: widget.venue.accentColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selectedSlots.isEmpty
                              ? null
                              : () {
                                  if (FirebaseAuth.instance.currentUser == null) {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const LoginScreen()),
                                    );
                                    return;
                                  }
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ConfirmationScreen(
                                        venue: widget.venue,
                                        date: _selectedDate,
                                        startTime: _selectedSlots.first.time,
                                        endTime: _selectedSlots.last.endTime,
                                        courtType: _isFullCourt
                                            ? 'Бүтэн талбай'
                                            : 'Хагас талбай',
                                        price: _totalPriceLabel,
                                      ),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedSlots.isNotEmpty
                                ? widget.venue.accentColor
                                : AppTheme.surface,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedSlots.isEmpty
                                    ? Icons.touch_app_rounded
                                    : Icons.check_circle_rounded,
                                color: _selectedSlots.isEmpty
                                    ? AppTheme.textSecondary
                                    : Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedSlots.isEmpty
                                    ? 'Цагаа сонгоно уу ↑'
                                    : 'Захиалах',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedSlots.isEmpty
                                      ? AppTheme.textSecondary
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dot(Color color) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      );
}

class _CourtTypeCard extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _CourtTypeCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.1)
                : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accentColor : AppTheme.divider,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected ? accentColor : AppTheme.textSecondary,
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? accentColor : AppTheme.divider,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 11)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: isSelected ? accentColor : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
