import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';
import 'booking_sheet.dart';
import 'notifications_screen.dart';
import '../services/notification_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Бүгд';
  String _searchQuery = '';
  String _selectedSort = 'Үнэлгээ';
  bool _onlyAvailable = false;
  final _searchController = TextEditingController();
  final _notifStore = NotificationStore.instance;

  @override
  void initState() {
    super.initState();
    _notifStore.addListener(_rebuild);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notifStore.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  final List<String> _categories = [
    'Бүгд',
    'Сагсан бөмбөг',
    'Волейбол',
  ];

  bool get _hasActiveFilters =>
      _selectedSort != 'Үнэлгээ' || _onlyAvailable;

  int _parsePrice(String price) =>
      int.tryParse(price.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

  List<SportVenue> get _filteredVenues {
    List<SportVenue> list = AppData.venues;

    if (_selectedCategory != 'Бүгд') {
      list = list.where((v) => v.type == _selectedCategory).toList();
    }
    if (_onlyAvailable) {
      list = list.where((v) => v.isAvailable).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((v) =>
              v.name.toLowerCase().contains(q) ||
              v.type.toLowerCase().contains(q) ||
              v.location.toLowerCase().contains(q))
          .toList();
    }
    switch (_selectedSort) {
      case 'Үнэлгээ':
        list = [...list]..sort((a, b) => b.rating.compareTo(a.rating));
      case 'Үнэ: бага':
        list = [...list]..sort(
            (a, b) => _parsePrice(a.pricePerHour).compareTo(_parsePrice(b.pricePerHour)));
      case 'Үнэ: өндөр':
        list = [...list]..sort(
            (a, b) => _parsePrice(b.pricePerHour).compareTo(_parsePrice(a.pricePerHour)));
    }
    return list;
  }

  void _showFilterSheet() {
    String tempSort = _selectedSort;
    bool tempAvailable = _onlyAvailable;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: AppTheme.divider),
                  left: BorderSide(color: AppTheme.divider),
                  right: BorderSide(color: AppTheme.divider),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    children: [
                      const Text(
                        'Шүүлтүүр',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setSheet(() {
                            tempSort = 'Үнэлгээ';
                            tempAvailable = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.divider,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Арилгах',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sort section
                  const Text(
                    'Эрэмбэлэх',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SortChip(
                        label: 'Үнэлгээ',
                        icon: Icons.star_rounded,
                        isSelected: tempSort == 'Үнэлгээ',
                        onTap: () => setSheet(() => tempSort = 'Үнэлгээ'),
                      ),
                      _SortChip(
                        label: 'Үнэ: бага → өндөр',
                        icon: Icons.arrow_upward_rounded,
                        isSelected: tempSort == 'Үнэ: бага',
                        onTap: () => setSheet(() => tempSort = 'Үнэ: бага'),
                      ),
                      _SortChip(
                        label: 'Үнэ: өндөр → бага',
                        icon: Icons.arrow_downward_rounded,
                        isSelected: tempSort == 'Үнэ: өндөр',
                        onTap: () => setSheet(() => tempSort = 'Үнэ: өндөр'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Availability section
                  const Text(
                    'Нээлттэй байдал',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => setSheet(() => tempAvailable = !tempAvailable),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: tempAvailable
                            ? AppTheme.success.withValues(alpha: 0.1)
                            : AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: tempAvailable
                              ? AppTheme.success
                              : AppTheme.divider,
                          width: tempAvailable ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Зөвхөн нээлттэй заалнууд',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: tempAvailable
                                  ? AppTheme.success
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: tempAvailable
                                    ? AppTheme.success
                                    : AppTheme.divider,
                                width: 1.5,
                              ),
                            ),
                            child: tempAvailable
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 14)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedSort = tempSort;
                          _onlyAvailable = tempAvailable;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Хэрэглэх'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            backgroundColor: AppTheme.primary,
            expandedHeight: 0,
            flexibleSpace: const FlexibleSpaceBar(),
            automaticallyImplyLeading: false,
            title: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppTheme.secondary,
                            size: 13,
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            'Даланзадгад',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Говийн Спорт',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          _notifStore.unreadCount > 0
                              ? Icons.notifications_rounded
                              : Icons.notifications_outlined,
                          color: _notifStore.unreadCount > 0
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                          size: 26,
                        ),
                        if (_notifStore.unreadCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primary,
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 16, minHeight: 16),
                              child: Text(
                                _notifStore.unreadCount > 9
                                    ? '9+'
                                    : '${_notifStore.unreadCount}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ── Хайлт ───────────────────────────────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _searchQuery.isNotEmpty
                            ? AppTheme.secondary
                            : AppTheme.divider,
                        width: _searchQuery.isNotEmpty ? 1.5 : 1,
                      ),
                      boxShadow: _searchQuery.isNotEmpty
                          ? [
                              BoxShadow(
                                color: AppTheme.secondary.withValues(alpha: 0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.search_rounded,
                            key: ValueKey(_searchQuery.isNotEmpty),
                            color: _searchQuery.isNotEmpty
                                ? AppTheme.secondary
                                : AppTheme.textSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Спорт заал хайх...',
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  key: const ValueKey('clear'),
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(10),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.divider,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: AppTheme.textSecondary,
                                      size: 14,
                                    ),
                                  ),
                                )
                              : GestureDetector(
                                  key: const ValueKey('filter'),
                                  onTap: _showFilterSheet,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.all(8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _hasActiveFilters
                                              ? AppTheme.secondary.withValues(alpha: 0.25)
                                              : AppTheme.secondary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: _hasActiveFilters
                                                ? AppTheme.secondary
                                                : AppTheme.secondary.withValues(alpha: 0.3),
                                            width: _hasActiveFilters ? 1.5 : 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.tune_rounded,
                                          color: AppTheme.secondary,
                                          size: 17,
                                        ),
                                      ),
                                      if (_hasActiveFilters)
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppTheme.accent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Говийн тэмээ баннер ──────────────────────────────────────
                  _GobiBanner(),

                  const SizedBox(height: 20),

                  // ── Статистик ────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          value: '${AppData.venues.length}',
                          label: 'Спорт заал',
                          color: AppTheme.secondary,
                        ),
                        Container(
                            width: 1, height: 28, color: AppTheme.divider),
                        _StatItem(
                          value: '08–20',
                          label: 'Цагийн хуваарь',
                          color: AppTheme.success,
                        ),
                        Container(
                            width: 1, height: 28, color: AppTheme.divider),
                        _StatItem(
                          value: '2',
                          label: 'Спортын төрөл',
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Ангилал chips ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.secondary
                            : AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.secondary
                              : AppTheme.divider,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: SectionHeader(
                title: 'Заалнууд (${_filteredVenues.length})',
              ),
            ),
          ),

          // ── Заалнуудын жагсаалт ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, i) {
                final venue = _filteredVenues[i];
                return VenueCard(
                  venue: venue,
                  onTap: () => showBookingSheet(context, venue),
                );
              }, childCount: _filteredVenues.length),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ── Sort Chip ─────────────────────────────────────────────────────────────────
class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.secondary.withValues(alpha: 0.15)
              : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.secondary : AppTheme.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppTheme.secondary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.secondary : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Говийн Спорт баннер ───────────────────────────────────────────────────────
class _GobiBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E1B05), Color(0xFF1A1004)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Одоо нээлттэй',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Даланзадгадын\nспорт заалнууд',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '08:00 – 20:00 • 1 цагийн слот',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              _BannerEmoji(emoji: '🐪'),
              const SizedBox(height: 8),
              _BannerEmoji(emoji: '🦅'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerEmoji extends StatelessWidget {
  final String emoji;
  const _BannerEmoji({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.secondary.withValues(alpha: 0.15),
        ),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}

// ── Статистик item ────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
