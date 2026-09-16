import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../../../core/utils/formatters.dart';

class CartSummary extends ConsumerWidget {
  const CartSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(Formatters.currency(cart.total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green.shade700)),
          ],
        ),
        const SizedBox(height: 8),
        if (cart.tableId != null)
          Text('Mesa ${cart.tableNumber ?? cart.tableId}', style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}
