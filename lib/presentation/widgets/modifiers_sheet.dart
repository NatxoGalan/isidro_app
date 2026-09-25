import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product_dto.dart';
import '../../../data/models/order_dto.dart';
import '../../../core/utils/formatters.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';

class ModifiersSheet extends ConsumerStatefulWidget {
  final ProductEntity product;
  const ModifiersSheet({super.key, required this.product});

  @override
  ConsumerState<ModifiersSheet> createState() => _ModifiersSheetState();
}

class _ModifiersSheetState extends ConsumerState<ModifiersSheet> {
  final Map<String, ModifierOption?> _selectedOptions = {};
  final _notesController = TextEditingController();
  bool _isTakeaway = false;

  @override
  void initState() {
    super.initState();
    for (final mod in widget.product.modifiers) {
      _selectedOptions[mod.modifierId] = mod.options.isNotEmpty ? mod.options.first : null;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      minChildSize: 0.3,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              Text(widget.product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(Formatters.currency(widget.product.basePrice), style: TextStyle(color: Colors.green.shade700, fontSize: 16)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    ...widget.product.modifiers.map((mod) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 8,
                          children: mod.options.map((opt) {
                            final isSelected = _selectedOptions[mod.modifierId]?.optionId == opt.optionId;
                            return ChoiceChip(
                              label: Text('${opt.name} ${opt.priceDelta > 0 ? "+${Formatters.currency(opt.priceDelta)}" : ""}'),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedOptions[mod.modifierId] = opt),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                      ],
                    )),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText: 'Notas de cocina...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Para llevar'),
                        const SizedBox(width: 8),
                        Switch(
                          value: _isTakeaway,
                          onChanged: (v) => setState(() => _isTakeaway = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addOrderItem,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text('Añadir ${Formatters.currency(widget.product.basePrice)}'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addOrderItem() {
    final modifiers = <AppliedModifier>[];
    double modPrice = 0;
    _selectedOptions.forEach((modId, opt) {
      if (opt != null) {
        modifiers.add(AppliedModifier(
          modifierId: modId,
          modifierName: widget.product.modifiers.firstWhere((m) => m.modifierId == modId).name,
          optionId: opt.optionId,
          optionName: opt.name,
          additionalPrice: opt.priceDelta,
        ));
        modPrice += opt.priceDelta;
      }
    });

    final cats = ref.read(categoriesProvider).valueOrNull;
    ref.read(cartProvider.notifier).addItem(OrderItemEntity(
      itemId: 'item_${DateTime.now().millisecondsSinceEpoch}',
      productId: widget.product.id,
      productName: widget.product.name,
      quantity: 1,
      unitPrice: widget.product.basePrice,
      totalPrice: widget.product.basePrice + modPrice,
      modifiers: modifiers,
      notes: _notesController.text,
      isTakeaway: _isTakeaway,
      createdAt: DateTime.now(),
      categoryId: widget.product.categoryId,
      categoryName: cats
              ?.where((c) => c.id == widget.product.categoryId)
              .map((c) => c.name)
              .firstOrNull ??
          '',
    ));
    Navigator.pop(context);
  }
}
