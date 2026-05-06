import 'package:flutter/foundation.dart';

class TabNavigator {
  static final ValueNotifier<int?> pendingTab = ValueNotifier(null);

  static void switchToBookings() {
    pendingTab.value = 1;
  }
}
