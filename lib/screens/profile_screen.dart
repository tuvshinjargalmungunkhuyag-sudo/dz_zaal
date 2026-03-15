import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профайл'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Профайл header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3D2008), Color(0xFF1C1006)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                // Avatar + мазаалай чимэглэл
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.secondary, AppTheme.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'Б',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.secondary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Center(
                          child: Text('🐻', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Батбаяр Дорж',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.phone_rounded,
                        color: AppTheme.textSecondary, size: 13),
                    SizedBox(width: 4),
                    Text(
                      '+976 9911-2233',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Статистик
                Row(
                  children: [
                    Expanded(
                        child: _StatPill(value: '12', label: 'Нийт захиалга')),
                    Container(
                        width: 1,
                        height: 30,
                        color: AppTheme.divider),
                    Expanded(
                        child:
                            _StatPill(value: '3', label: 'Хүлээгдэж буй')),
                    Container(
                        width: 1,
                        height: 30,
                        color: AppTheme.divider),
                    Expanded(child: _StatPill(value: '4.9★', label: 'Үнэлгээ')),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Говийн амьтдын зурвас ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _AnimalBadge(emoji: '🐪', label: 'Тэмээ'),
                _AnimalBadge(emoji: '🦅', label: 'Ёл шувуу'),
                _AnimalBadge(emoji: '🐻', label: 'Мазаалай'),
                _AnimalBadge(emoji: '🦎', label: 'Гүрвэл'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Тохиргоо ────────────────────────────────────────────────────────
          _MenuSection(
            title: 'Тохиргоо',
            items: [
              _MenuItem(
                icon: Icons.person_rounded,
                label: 'Мэдээлэл засах',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.notifications_rounded,
                label: 'Мэдэгдэл',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.lock_rounded,
                label: 'Нууц үг',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 16),

          _MenuSection(
            title: 'Апп',
            items: [
              _MenuItem(
                icon: Icons.help_rounded,
                label: 'Тусламж',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.star_rounded,
                label: 'Үнэлгээ өгөх',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.info_rounded,
                label: 'Апп тухай',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 24),

          TextButton(
            onPressed: () {},
            child: const Text(
              'Гарах',
              style: TextStyle(color: Colors.redAccent, fontSize: 15),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _AnimalBadge extends StatelessWidget {
  final String emoji;
  final String label;
  const _AnimalBadge({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  const _StatPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.secondary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    const Divider(
                      color: AppTheme.divider,
                      height: 1,
                      indent: 56,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.secondary, size: 18),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: AppTheme.textSecondary,
        size: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    );
  }
}
