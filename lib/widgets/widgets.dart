import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

// ── Venue Card ────────────────────────────────────────────────────────────────
class VenueCard extends StatelessWidget {
  final SportVenue venue;
  final VoidCallback onTap;

  const VenueCard({super.key, required this.venue, required this.onTap});


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Зүүн: дүрс ─────────────────────────────────────────────────
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    venue.accentColor.withValues(alpha: 0.25),
                    venue.accentColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: venue.accentColor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.sports_rounded,
                size: 26,
                color: venue.accentColor,
              ),
            ),
            const SizedBox(width: 12),
            // ── Дунд: нэр, байршил, рейтинг ────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.textSecondary,
                        size: 11,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          venue.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppTheme.warning, size: 13),
                      const SizedBox(width: 2),
                      Text(
                        venue.rating.toString(),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '(${venue.reviewCount})',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // ── Баруун: үнэ, боломж ─────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: venue.accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    venue.pricePerHour,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: venue.isAvailable
                            ? AppTheme.success
                            : AppTheme.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
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
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
              ],
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

  static const _fixedColor = Color(0xFF8B5CF6); // нил ягаан

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;

    final isHalfBooked = slot.halfCourtCount == 1 && !slot.hasFullCourt && !slot.isBooked;
    const halfColor = Color(0xFFF59E0B); // анбер/улбар шар

    if (slot.isFixed) {
      bg     = _fixedColor.withValues(alpha: 0.12);
      border = _fixedColor.withValues(alpha: 0.5);
      text   = _fixedColor;
    } else if (slot.isBooked) {
      bg     = AppTheme.divider.withValues(alpha: 0.7);
      border = AppTheme.divider;
      text   = AppTheme.textSecondary.withValues(alpha: 0.6);
    } else if (slot.isSelected) {
      bg     = accentColor.withValues(alpha: 0.2);
      border = accentColor;
      text   = accentColor;
    } else if (isHalfBooked) {
      bg     = halfColor.withValues(alpha: 0.1);
      border = halfColor.withValues(alpha: 0.5);
      text   = halfColor;
    } else {
      bg     = AppTheme.surface;
      border = AppTheme.divider;
      text   = AppTheme.textPrimary;
    }

    return GestureDetector(
      onTap: (slot.isBooked || slot.isFixed) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (slot.isBooked)
              const Icon(
                Icons.block_rounded,
                size: 14,
                color: AppTheme.textSecondary,
              )
            else if (isHalfBooked)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.vertical_split_rounded, size: 11, color: text),
                  const SizedBox(width: 2),
                  Text(
                    slot.time,
                    style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              )
            else
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
              slot.isFixed
                  ? 'Гэрээт'
                  : slot.isBooked
                      ? 'Захиалаатай'
                      : isHalfBooked
                          ? 'Нэг хагас авсан'
                          : slot.endTime,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: slot.isFixed
                    ? _fixedColor.withValues(alpha: 0.8)
                    : slot.isBooked
                        ? AppTheme.textSecondary.withValues(alpha: 0.4)
                        : text.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: slot.isFixed ? FontWeight.w600 : FontWeight.w400,
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
      {'icon': Icons.calendar_month_rounded, 'label': 'Захиалга'},
      {'icon': Icons.person_rounded,         'label': 'Профайл'},
      {'icon': Icons.smart_toy_rounded,      'label': 'AI'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: const Border(
          top: BorderSide(color: AppTheme.divider, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isActive = currentIndex == i;

              return GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.secondary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: isActive ? Colors.white : AppTheme.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          color: isActive ? Colors.white : AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
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
