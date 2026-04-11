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
  String _searchQuery = '';
  String _selectedSort = 'Үнэлгээ';
  bool _onlyAvailable = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _notifStore = NotificationStore.instance;

  @override
  void initState() {
    super.initState();
    _notifStore.addListener(_rebuild);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _notifStore.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  bool get _hasActiveFilters =>
      _selectedSort != 'Үнэлгээ' || _onlyAvailable;

  int _parsePrice(String price) =>
      int.tryParse(price.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

  List<SportVenue> get _filteredVenues {
    List<SportVenue> list = AppData.venues;

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
                            decoration: const BoxDecoration(
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
    final venues = _filteredVenues;
    return Scaffold(
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // ── AppBar: гарчиг + мэдэгдэл ─────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppTheme.primary,
            automaticallyImplyLeading: false,
            title: const Text(
              'Говийн Спорт',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
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
                          top: 6,
                          right: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppTheme.primary, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Хайлт ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GestureDetector(
                onTap: () => _searchFocusNode.requestFocus(),
                child: AnimatedContainer(
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
                  boxShadow: [
                    BoxShadow(
                      color: _searchQuery.isNotEmpty
                          ? AppTheme.secondary.withValues(alpha: 0.18)
                          : Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(
                      Icons.search_rounded,
                      color: _searchQuery.isNotEmpty
                          ? AppTheme.secondary
                          : AppTheme.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
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
                        onChanged: (val) =>
                            setState(() => _searchQuery = val),
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
                                decoration: const BoxDecoration(
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
                                          ? AppTheme.secondary
                                              .withValues(alpha: 0.25)
                                          : AppTheme.secondary
                                              .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _hasActiveFilters
                                            ? AppTheme.secondary
                                            : AppTheme.secondary
                                                .withValues(alpha: 0.3),
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
              ),
            ),
          ),

          // ── Заалнуудын жагсаалт ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: venues.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            color: AppTheme.textSecondary,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '"$_searchQuery" олдсонгүй',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => VenueCard(
                        venue: venues[i],
                        onTap: () => showBookingSheet(context, venues[i]),
                      ),
                      childCount: venues.length,
                    ),
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
