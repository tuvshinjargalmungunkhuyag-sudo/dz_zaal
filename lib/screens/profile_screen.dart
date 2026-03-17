import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userName;
  int _totalBookings = 0;
  int _upcomingBookings = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final phone = AuthService.currentPhone;

      final name = await AuthService.getUserName();

      int total = 0;
      int upcoming = 0;
      if (phone != null) {
        final snap = await FirebaseFirestore.instance
            .collection('bookings')
            .where('userPhone', isEqualTo: phone)
            .get();
        total = snap.docs.length;
        upcoming = snap.docs
            .where((d) => d.data()['status'] == 'upcoming')
            .length;
      }

      if (mounted) {
        setState(() {
          _userName = name;
          _totalBookings = total;
          _upcomingBookings = upcoming;
          _isLoading = false;
        });
        if (name == null || name.isEmpty) {
          _askForName();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _askForName() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Нэрээ оруулна уу',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Таны нэр',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.secondary),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.secondary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              try {
                await AuthService.saveUserName(name);
                if (mounted) {
                  setState(() => _userName = name);
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Алдаа: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Хадгалах',
                style: TextStyle(
                    color: AppTheme.secondary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Гарах уу?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Аккаунтаас гарах уу?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Болих',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Гарах',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) await AuthService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final phone = AuthService.currentPhone ?? '';
    final initials = (_userName?.isNotEmpty == true)
        ? _userName![0].toUpperCase()
        : phone.isNotEmpty
            ? phone[0]
            : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профайл'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Гарах',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.secondary, strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Профайл header ──────────────────────────────────────────
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
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.secondary, AppTheme.accent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
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
                                child: Text('🐻',
                                    style: TextStyle(fontSize: 13)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _userName ?? 'Хэрэглэгч',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_rounded,
                              color: AppTheme.textSecondary, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '+976 ${phone.substring(0, 4)}-${phone.substring(4)}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _StatPill(
                                value: '$_totalBookings',
                                label: 'Нийт захиалга'),
                          ),
                          Container(
                              width: 1, height: 30, color: AppTheme.divider),
                          Expanded(
                            child: _StatPill(
                                value: '$_upcomingBookings',
                                label: 'Хүлээгдэж буй'),
                          ),
                          Container(
                              width: 1, height: 30, color: AppTheme.divider),
                          const Expanded(
                            child: _StatPill(value: '🏅', label: 'Гишүүн'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Говийн амьтдын зурвас ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _AnimalBadge(emoji: '🐪', label: 'Тэмээ'),
                      _AnimalBadge(emoji: '🦅', label: 'Ёл шувуу'),
                      _AnimalBadge(emoji: '🐻', label: 'Мазаалай'),
                      _AnimalBadge(emoji: '🦎', label: 'Гүрвэл'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Тохиргоо ────────────────────────────────────────────────
                _MenuSection(
                  title: 'Тохиргоо',
                  items: [
                    _MenuItem(
                      icon: Icons.notifications_rounded,
                      label: 'Мэдэгдэл',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.help_rounded,
                      label: 'Тусламж',
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

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.redAccent, size: 18),
                    label: const Text(
                      'Гарах',
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
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
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 10),
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
  const _MenuItem(
      {required this.icon, required this.label, required this.onTap});

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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    );
  }
}
