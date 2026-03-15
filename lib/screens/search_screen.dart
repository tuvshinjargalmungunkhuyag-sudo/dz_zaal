import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'Бүгд';
  String _selectedSort = 'Үнэлгээ';

  final List<String> _categories = [
    'Бүгд',
    'Сагсан бөмбөг',
    'Волейбол',
  ];

  final List<String> _sortOptions = ['Үнэлгээ', 'Үнэ: бага', 'Үнэ: өндөр'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SportVenue> get _results {
    List<SportVenue> list = AppData.venues;

    if (_selectedCategory != 'Бүгд') {
      list = list.where((v) => v.type == _selectedCategory).toList();
    }

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where(
            (v) =>
                v.name.toLowerCase().contains(q) ||
                v.type.toLowerCase().contains(q) ||
                v.location.toLowerCase().contains(q) ||
                v.facilities.any((f) => f.toLowerCase().contains(q)),
          )
          .toList();
    }

    switch (_selectedSort) {
      case 'Үнэлгээ':
        list = [...list]..sort((a, b) => b.rating.compareTo(a.rating));
      case 'Үнэ: бага':
        list = [...list]..sort(
          (a, b) => _parsePrice(a.pricePerHour).compareTo(
            _parsePrice(b.pricePerHour),
          ),
        );
      case 'Үнэ: өндөр':
        list = [...list]..sort(
          (a, b) => _parsePrice(b.pricePerHour).compareTo(
            _parsePrice(a.pricePerHour),
          ),
        );
    }

    return list;
  }

  int _parsePrice(String price) {
    return int.tryParse(price.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header + Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Хайх',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search input
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _query.isNotEmpty
                            ? AppTheme.secondary
                            : AppTheme.divider,
                        width: _query.isNotEmpty ? 1.5 : 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: false,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Заалны нэр, төрөл, байршил...',
                        hintStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppTheme.textSecondary,
                          size: 22,
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 20,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (val) => setState(() => _query = val),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Sort row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                    children: [
                      const Text(
                        'Эрэмбэ:',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ..._sortOptions.map(
                        (s) => GestureDetector(
                          onTap: () => setState(() => _selectedSort = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedSort == s
                                  ? AppTheme.secondary.withValues(alpha: 0.15)
                                  : AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedSort == s
                                    ? AppTheme.secondary
                                    : AppTheme.divider,
                              ),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                color: _selectedSort == s
                                    ? AppTheme.secondary
                                    : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: _selectedSort == s
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
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

            const SizedBox(height: 16),

            // Category chips
            SizedBox(
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
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
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

            const SizedBox(height: 12),

            // Result count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${results.length} заал олдлоо',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Results list
            Expanded(
              child: results.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final venue = results[i];
                        return VenueCard(
                          venue: venue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(venue: venue),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Илэрц олдсонгүй',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Өөр түлхүүр үг оруулж үзнэ үү',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
