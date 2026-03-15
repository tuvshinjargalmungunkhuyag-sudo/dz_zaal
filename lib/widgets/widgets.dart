import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

// ── Venue Card ────────────────────────────────────────────────────────────────
class VenueCard extends StatelessWidget {
  final SportVenue venue;
  final VoidCallback onTap;

  const VenueCard({super.key, required this.venue, required this.onTap});

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

  // Говийн амьтдын чимэглэл — заал тус бүрт
  String _getAnimalEmoji(String type) {
    switch (type) {
      case 'Сагсан бөмбөг':
        return '🦅';
      case 'Фитнес':
        return '🐻';
      case 'Теннис':
        return '🦎';
      case 'Хөл бөмбөг':
        return '🐪';
      case 'Бөх':
        return '🐻';
      default:
        return '🦅';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: venue.accentColor.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Баннер ─────────────────────────────────────────────────────
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    venue.accentColor.withValues(alpha: 0.25),
                    const Color(0xFF1C1006),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Спорт дүрс
                  Center(
                    child: Icon(
                      _getIcon(venue.type),
                      size: 70,
                      color: venue.accentColor.withValues(alpha: 0.5),
                    ),
                  ),
                  // Говийн амьтан чимэглэл
                  Positioned(
                    bottom: 12,
                    right: 16,
                    child: Text(
                      _getAnimalEmoji(venue.type),
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  // Төрлийн badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: venue.accentColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        venue.type,
                        style: TextStyle(
                          color: venue.accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Нээлттэй/Бүрэн badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: venue.isAvailable
                            ? AppTheme.success.withValues(alpha: 0.2)
                            : AppTheme.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: venue.isAvailable
                                  ? AppTheme.success
                                  : AppTheme.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            venue.isAvailable ? 'Нээлттэй' : 'Бүрэн',
                            style: TextStyle(
                              color: venue.isAvailable
                                  ? AppTheme.success
                                  : AppTheme.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Мэдээлэл ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          venue.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: venue.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          venue.pricePerHour,
                          style: TextStyle(
                            color: venue.accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.textSecondary,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          venue.location,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppTheme.warning,
                            size: 15,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            venue.rating.toString(),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '(${venue.reviewCount})',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ...venue.facilities.take(2).map(
                        (f) => Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.divider,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            f,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
    );
  }
}

// ── Time Slot Chip ────────────────────────────────────────────────────────────
class TimeSlotChip extends StatelessWidget {
  final TimeSlot slot;
  final VoidCallback onTap;
  final Color accentColor;

  const TimeSlotChip({
    super.key,
    required this.slot,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;

    if (slot.isBooked) {
      bg = AppTheme.divider.withValues(alpha: 0.5);
      border = AppTheme.divider;
      text = AppTheme.textSecondary.withValues(alpha: 0.5);
    } else if (slot.isSelected) {
      bg = accentColor.withValues(alpha: 0.2);
      border = accentColor;
      text = accentColor;
    } else {
      bg = AppTheme.cardColor;
      border = AppTheme.divider;
      text = AppTheme.textPrimary;
    }

    return GestureDetector(
      onTap: slot.isBooked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot.time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              slot.isBooked ? 'Захиалаатай' : slot.endTime,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: slot.isBooked
                    ? AppTheme.textSecondary.withValues(alpha: 0.4)
                    : text.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Bottom Nav ─────────────────────────────────────────────────────────
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_rounded,          'label': 'Нүүр'},
      {'icon': Icons.search_rounded,         'label': 'Хайх'},
      {'icon': Icons.calendar_month_rounded, 'label': 'Захиалга'},
      {'icon': Icons.person_rounded,         'label': 'Профайл'},
      {'icon': Icons.smart_toy_rounded,      'label': 'AI'},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          top: BorderSide(color: AppTheme.divider, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isActive = currentIndex == i;

          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.secondary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: isActive
                        ? AppTheme.secondary
                        : AppTheme.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: isActive
                          ? AppTheme.secondary
                          : AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionText!,
              style: const TextStyle(
                color: AppTheme.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
