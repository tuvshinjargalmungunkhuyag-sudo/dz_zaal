import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';
import 'confirmation_screen.dart';

class DetailScreen extends StatefulWidget {
  final SportVenue venue;

  const DetailScreen({super.key, required this.venue});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  DateTime _selectedDate = DateTime.now();
  late List<TimeSlot> _timeSlots;
  TimeSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _timeSlots = AppData.generateTimeSlots(widget.venue.id, _selectedDate);
  }

  void _selectSlot(TimeSlot slot) {
    setState(() {
      for (var s in _timeSlots) {
        s.isSelected = false;
      }
      slot.isSelected = true;
      _selectedSlot = slot;
    });
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
    return '${date.year} оны ${months[date.month - 1]}ийн ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero App Bar
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppTheme.textPrimary,
                  size: 18,
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.favorite_border_rounded,
                    color: AppTheme.textPrimary,
                    size: 20,
                  ),
                  onPressed: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.venue.accentColor.withValues(alpha: 0.4),
                      AppTheme.primary,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getIcon(widget.venue.type),
                    size: 120,
                    color: widget.venue.accentColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.venue.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.venue.location,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
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
                            widget.venue.pricePerHour,
                            style: TextStyle(
                              color: widget.venue.accentColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            '/ цаг',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Rating & reviews
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoPill(
                          icon: Icons.star_rounded,
                          value: widget.venue.rating.toString(),
                          label: 'Үнэлгээ',
                          color: AppTheme.warning,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppTheme.divider,
                        ),
                        _InfoPill(
                          icon: Icons.chat_bubble_rounded,
                          value: '${widget.venue.reviewCount}',
                          label: 'Сэтгэгдэл',
                          color: AppTheme.secondary,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppTheme.divider,
                        ),
                        _InfoPill(
                          icon: Icons.access_time_rounded,
                          value: '08:00',
                          label: 'Нээх',
                          color: AppTheme.success,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Facilities
                  const SectionHeader(title: 'Тоноглол'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: widget.venue.facilities.map((f) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: widget.venue.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.venue.accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _facilityIcon(f),
                              color: widget.venue.accentColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              f,
                              style: TextStyle(
                                color: widget.venue.accentColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // Date Selection
                  const SectionHeader(title: 'Өдөр сонгох'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 14,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final date = DateTime.now().add(Duration(days: i));
                        final isSelected =
                            _selectedDate.day == date.day &&
                            _selectedDate.month == date.month;
                        const weekDays = [
                          'Да',
                          'Мя',
                          'Лх',
                          'Пү',
                          'Ба',
                          'Бя',
                          'Ня',
                        ];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                              _timeSlots = AppData.generateTimeSlots(widget.venue.id, date);
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 56,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? widget.venue.accentColor
                                  : AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(16),
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
                                  weekDays[date.weekday - 1],
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
                                    fontSize: 20,
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

                  const SizedBox(height: 28),

                  // Time Slots
                  Row(
                    children: [
                      const Text(
                        'Цаг сонгох',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      // Legend
                      _Legend(color: AppTheme.divider, label: 'Захиалагдсан'),
                      const SizedBox(width: 12),
                      _Legend(
                        color: widget.venue.accentColor,
                        label: 'Сонгосон',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                    itemBuilder: (context, i) {
                      return TimeSlotChip(
                        slot: _timeSlots[i],
                        onTap: () => _selectSlot(_timeSlots[i]),
                        accentColor: widget.venue.accentColor,
                      );
                    },
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Booking Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: const Border(
            top: BorderSide(color: AppTheme.divider, width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedSlot != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_rounded,
                        color: widget.venue.accentColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_formatDate(_selectedDate)}, ${_selectedSlot!.time} – ${_selectedSlot!.endTime}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        widget.venue.pricePerHour,
                        style: TextStyle(
                          color: widget.venue.accentColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedSlot == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConfirmationScreen(
                                venue: widget.venue,
                                date: _selectedDate,
                                selectedSlots: [_selectedSlot!],
                                courtType: 'Бүтэн талбай',
                                price: widget.venue.pricePerHour,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedSlot != null
                        ? widget.venue.accentColor
                        : AppTheme.divider,
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _selectedSlot == null ? 'Цаг сонгоно уу' : 'Захиалах',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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

  IconData _facilityIcon(String name) {
    switch (name) {
      case 'Душ':
        return Icons.shower_rounded;
      case 'Паркинг':
        return Icons.local_parking_rounded;
      case 'WiFi':
        return Icons.wifi_rounded;
      case 'Тренер':
        return Icons.person_rounded;
      case 'Гардероб':
        return Icons.checkroom_rounded;
      case 'Камер':
        return Icons.videocam_rounded;
      case 'Гэрэлтүүлэг':
        return Icons.lightbulb_rounded;
      case 'Сейф':
        return Icons.lock_rounded;
      case 'Ракетка':
        return Icons.sports_tennis_rounded;
      case 'Матрац':
        return Icons.bed_rounded;
      case 'Тренажер':
        return Icons.fitness_center_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}
