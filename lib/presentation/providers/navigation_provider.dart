import 'package:flutter_riverpod/legacy.dart';

final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((
  ref,
) {
  return NavigationNotifier();
});

class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0);

  void setIndex(int index) {
    if (index >= 0 && index <= 4) state = index;
  }

  void goToDashboard() => setIndex(0);
  void goToPos() => setIndex(1);
  void goToInventory() => setIndex(2);
  void goToCustomers() => setIndex(3);
  void goToSettings() => setIndex(4);
}
