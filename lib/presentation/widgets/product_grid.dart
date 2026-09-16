import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product_dto.dart';
import '../../../data/models/order_dto.dart';
import '../providers/cart_provider.dart';
import 'modifiers_sheet.dart';
import 'product_card.dart';

class ProductGrid extends ConsumerStatefulWidget {
  const ProductGrid({super.key});

  @override
  ConsumerState<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends ConsumerState<ProductGrid> {
  String _selectedCategory = 'Todos';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Buscar...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: ['Todos', 'Tapas', 'Bebidas', 'Bocadillos', 'Varios'].map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (v) => setState(() => _selectedCategory = cat),
                  backgroundColor: isSelected ? Colors.green.shade100 : Colors.grey.shade100,
                  selectedColor: Colors.green.shade200,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: products.when(
            data: (data) {
              final filtered = data.where((p) =>
                (_selectedCategory == 'Todos' || p.name.toLowerCase().contains(_selectedCategory.toLowerCase())) &&
                (_searchQuery.isEmpty || p.name.toLowerCase().contains(_searchQuery))
              ).toList();
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.5,
                ),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => ProductCard(
                  product: filtered[i],
                  onAdd: () => _addToCart(filtered[i]),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  void _addToCart(ProductEntity product) {
    if (product.modifiers.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ModifiersSheet(product: product),
      );
      return;
    }
    ref.read(cartProvider.notifier).addItem(OrderItemEntity(
      itemId: 'item_${DateTime.now().millisecondsSinceEpoch}',
      productId: product.id,
      productName: product.name,
      quantity: 1,
      unitPrice: product.basePrice,
      totalPrice: product.basePrice,
      modifiers: [],
      notes: '',
      createdAt: DateTime.now(),
    ));
  }
}

final productsProvider = StreamProvider<List<ProductEntity>>((ref) {
  return const Stream.empty();
});
