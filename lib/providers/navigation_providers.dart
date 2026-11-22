import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_providers.dart';

/// The customer's tabs, in the order they are shown.
enum CustomerTab { shop, cart, orders, account }

/// The tab on screen, so any page can send the customer to another tab.
final customerTabProvider = NotifierProvider<CustomerTabNotifier, CustomerTab>(
  CustomerTabNotifier.new,
);

class CustomerTabNotifier extends Notifier<CustomerTab> {
  @override
  CustomerTab build() {
    ref.watch(userIdProvider);
    return CustomerTab.shop;
  }

  void show(CustomerTab tab) => state = tab;
}
