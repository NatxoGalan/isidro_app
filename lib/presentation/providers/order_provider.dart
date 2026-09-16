import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';

class OrderNotifier extends StateNotifier<AsyncValue<String?>> {
  final CartNotifier _cart;

  OrderNotifier(this._cart) : super(const AsyncValue.data(null));

  Future<void> sendToKitchen() async {
    if (_cart.isEmpty || _cart.state.tableId == null) return;

    state = const AsyncValue.loading();
    try {
      await _cart.sendToKitchen();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Paga y cierra la mesa
  Future<void> closeTable() async {
    state = const AsyncValue.loading();
    try {
      await _cart.closeTable();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, AsyncValue<String?>>((ref) {
  return OrderNotifier(ref.read(cartProvider.notifier));
});
