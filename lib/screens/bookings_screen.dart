import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _filterIndex = 0;

  static const _allBookings = [
    (venue: 0, date: 'Мягмар, 11 3-р сар', time: '10:00 – 11:00', status: 'active', code: 'DBK-4821'),
    (venue: 3, date: 'Лхагва, 12 3-р сар', time: '14:00 – 15:00', status: 'upcoming', code: 'DBK-3917'),
    (venue: 1, date: 'Даваа, 3 3-р сар', time: '09:00 – 10:00', status: 'completed', code: 'DBK-2145'),
  ];

  List<({int venue, String date, String time, String status, String code})> get _filtered {
    if (_filterIndex == 0) return _allBookings;
    const statusMap = {1: 'active', 2: 'upcoming', 3: 'completed'};
    return _allBookings.where((b) => b.status == statusMap[_filterIndex]).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Миний захиалгууд'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _BookingStatusFilter(
            selected: _filterIndex,
            onSelect: (i) => setState(() => _filterIndex = i),
          ),
          const SizedBox(height: 20),
          ..._filtered.map((b) => _BookingCard(
            venue: AppData.venues[b.venue],
            date: b.date,
            time: b.time,
            status: b.status,
            code: b.code,
          )),
          if (_filtered.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Text(
                  'Захиалга олдсонгүй',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BookingStatusFilter extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _BookingStatusFilter({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final tabs = ['Бүгд', 'Идэвхтэй', 'Хүлээгдэж буй', 'Дууссан'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final isActive = selected == e.key;
          return GestureDetector(
            onTap: () => onSelect(e.key),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.secondary : AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppTheme.secondary : AppTheme.divider,
                ),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final SportVenue venue;
  final String date;
  final String time;
  final String status;
  final String code;

  const _BookingCard({
    required this.venue,
    required this.date,
    required this.time,
    required this.status,
    required this.code,
  });

  Color get _statusColor {
    switch (status) {
      case 'active':
        return AppTheme.success;
      case 'upcoming':
        return AppTheme.secondary;
      case 'completed':
        return AppTheme.textSecondary;
      default:
        return AppTheme.textSecondary;
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'active':
        return 'Идэвхтэй';
      case 'upcoming':
        return 'Хүлээгдэж буй';
      case 'completed':
        return 'Дууссан';
      default:
        return '';
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'Сагсан бөмбөг':
        return Icons.sports_basketball_rounded;
      case 'Фитнес':
        return Icons.fitness_center_rounded;
      case 'Теннис':
        return Icons.sports_tennis_rounded;
      case 'Хөл бөмбөг':
        return Icons.sports_soccer_rounded;
      case 'Бөх':
        return Icons.sports_martial_arts_rounded;
      default:
        return Icons.sports_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: venue.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getIcon(venue.type),
                  color: venue.accentColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      venue.location,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: AppTheme.textSecondary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  date,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.access_time_rounded,
                color: AppTheme.textSecondary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  time,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                code,
                style: TextStyle(
                  color: venue.accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          if (status == 'upcoming') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.divider),
                      foregroundColor: AppTheme.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Цуцлах'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: venue.accentColor,
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('QR харах'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
