import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../../../core/utils/formatters.dart';

class OrderTabs extends ConsumerWidget {
  const OrderTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.green.shade700,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green.shade700,
            tabs: const [
              Tab(text: 'Pedido'),
              Tab(text: 'Comanda'),
              Tab(text: 'Actividad'),
            ],
          ),
          SizedBox(
            height: 200,
            child: TabBarView(
              children: [
                _orderList(cart),
                _comandaList(cart, ref),
                const Center(child: Text('Historial de actividad')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderList(CartState cart) {
    if (cart.items.isEmpty) {
      return const Center(child: Text('Sin pedidos'));
    }
    return ListView.builder(
      itemCount: cart.items.length,
      itemBuilder: (_, i) {
        final item = cart.items[i];
        return ListTile(
          title: Text('${item.quantity}x ${item.productName}'),
          trailing: Text(Formatters.currency(item.totalPrice * item.quantity)),
        );
      },
    );
  }

  Widget _comandaList(CartState cart, WidgetRef ref) {
    if (cart.items.isEmpty) {
      return const Center(child: Text('Carrito vacío'));
    }
    return ListView.builder(
      itemCount: cart.items.length,
      itemBuilder: (_, i) {
        final item = cart.items[i];
        return ListTile(
          title: Text('${item.quantity}x ${item.productName}'),
          subtitle: Text(Formatters.currency(item.totalPrice * item.quantity)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.itemId, item.quantity - 1),
              ),
              Text('${item.quantity}'),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.itemId, item.quantity + 1),
              ),
            ],
          ),
        );
      },
    );
  }
}
