import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_sizes.dart';
import '../providers/cart_provider.dart';
import '../widgets/product_grid.dart';
import '../widgets/category_pills.dart';
import '../widgets/search_bar.dart';
import '../widgets/cart_summary.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Carta'),
        centerTitle: true,
        actions: [
          if (cart.itemCount > 0)
            Badge(
              label: Text('${cart.itemCount}'),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {},
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          const SearchBarWidget(),
          const CategoryPills(),
          const Expanded(child: ProductGrid()),
          if (cart.itemCount > 0)
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: const CartSummary(),
            ),
        ],
      ),
    );
  }
}
