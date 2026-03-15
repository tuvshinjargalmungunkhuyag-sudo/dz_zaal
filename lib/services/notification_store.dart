import 'package:flutter/foundation.dart';
import '../models/models.dart';

class NotificationStore extends ChangeNotifier {
  static final NotificationStore _instance = NotificationStore._();
  static NotificationStore get instance => _instance;
  NotificationStore._() {
    _seedInitial();
  }

  final List<AppNotification> _items = [];

  List<AppNotification> get all =>
      [..._items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int get unreadCount => _items.where((n) => !n.isRead).length;

  void add(AppNotification n) {
    _items.add(n);
    notifyListeners();
  }

  void markRead(String id) {
    final n = _items.where((n) => n.id == id).firstOrNull;
    if (n != null && !n.isRead) {
      n.isRead = true;
      notifyListeners();
    }
  }

  void markAllRead() {
    bool changed = false;
    for (final n in _items) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void remove(String id) {
    _items.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void _seedInitial() {
    final now = DateTime.now();
    _items.addAll([
      AppNotification(
        id: 'promo_1',
        type: AppNotificationType.promo,
        title: 'Эхний захиалгад 30% хямдрал',
        body: 'Говийн Спорт-д тавтай морил! Эхний захиалгаа хийхэд 30% хямдрал эдлээрэй.',
        createdAt: now.subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
      AppNotification(
        id: 'system_1',
        type: AppNotificationType.system,
        title: 'Тавтай морил',
        body: 'Говийн Спорт апп-д тавтай морилно уу. Даланзадгадын шилдэг заалнуудыг захиалаарай.',
        createdAt: now.subtract(const Duration(hours: 1)),
        isRead: true,
      ),
    ]);
  }
}
