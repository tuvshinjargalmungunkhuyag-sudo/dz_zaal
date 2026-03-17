import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _filterIndex = 0;

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> all) {
    if (_filterIndex == 0) return all;
    const statusMap = {1: 'active', 2: 'upcoming', 3: 'completed'};
    return all.where((b) => b['status'] == statusMap[_filterIndex]).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Миний захиалгууд'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userPhone', isEqualTo: AuthService.currentPhone)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data?.docs
                  .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
                  .toList() ??
              [];
          final filtered = _filter(all);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _BookingStatusFilter(
                selected: _filterIndex,
                onSelect: (i) => setState(() => _filterIndex = i),
              ),
              const SizedBox(height: 20),
              ...filtered.map((b) => _BookingCard(booking: b)),
              if (filtered.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Text(
                      'Захиалга олдсонгүй',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 15),
                    ),
                  ),
                ),
            ],
          );
        },
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  color:
                      isActive ? AppTheme.primary : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w400,
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
  final Map<String, dynamic> booking;

  const _BookingCard({required this.booking});

  Color get _statusColor {
    switch (booking['status']) {
      case 'active':
        return AppTheme.success;
      case 'upcoming':
        return AppTheme.secondary;
      default:
        return AppTheme.textSecondary;
    }
  }

  String get _statusLabel {
    switch (booking['status']) {
      case 'active':
        return 'Идэвхтэй';
      case 'upcoming':
        return 'Хүлээгдэж буй';
      case 'completed':
        return 'Дууссан';
      case 'cancelled':
        return 'Цуцлагдсан';
      default:
        return '';
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'Сагсан бөмбөг':
        return Icons.sports_basketball_rounded;
      case 'Волейбол':
        return Icons.sports_volleyball_rounded;
      case 'Фитнес':
        return Icons.fitness_center_rounded;
      default:
        return Icons.sports_rounded;
    }
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '';
    final date = (ts as Timestamp).toDate();
    const months = [
      '1-р сар', '2-р сар', '3-р сар', '4-р сар',
      '5-р сар', '6-р сар', '7-р сар', '8-р сар',
      '9-р сар', '10-р сар', '11-р сар', '12-р сар',
    ];
    const weekDays = ['Да', 'Мя', 'Лх', 'Пү', 'Ба', 'Бя', 'Ня'];
    return '${weekDays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(booking['venueAccentColor'] ?? 0xFF00D4FF);

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
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getIcon(booking['venueType'] ?? ''),
                  color: accentColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['venueName'] ?? '',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking['venueLocation'] ?? '',
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
                    horizontal: 10, vertical: 5),
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
              const Icon(Icons.calendar_today_rounded,
                  color: AppTheme.textSecondary, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _formatDate(booking['date']),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.access_time_rounded,
                  color: AppTheme.textSecondary, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${booking['timeSlot']}–${booking['timeSlotEnd']}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                booking['code'] ?? '',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          if (booking['status'] == 'upcoming') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await ApiService.cancelBooking(booking['id']);
                    },
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
              ],
            ),
          ],
        ],
      ),
    );
  }
}
