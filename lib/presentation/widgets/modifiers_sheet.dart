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
  final Map<String, Set<String>> _selectedMulti = {};
  final _notesController = TextEditingController();
  bool _isTakeaway = false;

  @override
  void initState() {
    super.initState();
    for (final mod in widget.product.modifiers) {
      if (mod.multi) {
        _selectedMulti[mod.modifierId] = {};
      } else {
        _selectedOptions[mod.modifierId] =
            mod.options.isNotEmpty ? mod.options.first : null;
      }
    }
  }

  /// Precio total con extras seleccionados.
  double get _totalWithMods {
    var total = widget.product.basePrice;
    for (final opt in _selectedOptions.values) {
      if (opt != null) total += opt.priceDelta;
    }
    for (final entry in _selectedMulti.entries) {
      final mod = widget.product.modifiers
          .firstWhere((m) => m.modifierId == entry.key);
      for (final opt in mod.options) {
        if (entry.value.contains(opt.optionId)) total += opt.priceDelta;
      }
    }
    return total;
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
                    ...widget.product.modifiers.map((mod) {
                      if (mod.multi) {
                        final selected =
                            _selectedMulti[mod.modifierId] ?? <String>{};
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mod.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Wrap(
                              spacing: 8,
                              children: mod.options.map((opt) {
                                final isSelected =
                                    selected.contains(opt.optionId);
                                return FilterChip(
                                  label: Text(
                                      '${opt.name} ${opt.priceDelta > 0 ? "+${Formatters.currency(opt.priceDelta)}" : ""}'),
                                  selected: isSelected,
                                  onSelected: (_) => setState(() {
                                    final set =
                                        _selectedMulti[mod.modifierId] ??=
                                            <String>{};
                                    if (isSelected) {
                                      set.remove(opt.optionId);
                                    } else {
                                      set.add(opt.optionId);
                                    }
                                  }),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mod.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Wrap(
                            spacing: 8,
                            children: mod.options.map((opt) {
                              final isSelected =
                                  _selectedOptions[mod.modifierId]?.optionId ==
                                      opt.optionId;
                              return ChoiceChip(
                                label: Text(
                                    '${opt.name} ${opt.priceDelta > 0 ? "+${Formatters.currency(opt.priceDelta)}" : ""}'),
                                selected: isSelected,
                                onSelected: (_) => setState(() =>
                                    _selectedOptions[mod.modifierId] = opt),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),
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
                  child: Text('Añadir ${Formatters.currency(_totalWithMods)}'),
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
    _selectedOptions.forEach((modId, opt) {
      if (opt != null) {
        modifiers.add(AppliedModifier(
          modifierId: modId,
          modifierName: widget.product.modifiers.firstWhere((m) => m.modifierId == modId).name,
          optionId: opt.optionId,
          optionName: opt.name,
          additionalPrice: opt.priceDelta,
        ));
      }
    });
    for (final entry in _selectedMulti.entries) {
      final mod = widget.product.modifiers
          .firstWhere((m) => m.modifierId == entry.key);
      for (final opt in mod.options) {
        if (entry.value.contains(opt.optionId)) {
          modifiers.add(AppliedModifier(
            modifierId: mod.modifierId,
            modifierName: mod.name,
            optionId: opt.optionId,
            optionName: opt.name,
            additionalPrice: opt.priceDelta,
          ));
        }
      }
    }
    // El precio unitario incluye los extras: así subtotal y tickets cobran bien
    final unitPrice = _totalWithMods;

    final cats = ref.read(categoriesProvider).valueOrNull;
    ref.read(cartProvider.notifier).addItem(OrderItemEntity(
      itemId: 'item_${DateTime.now().millisecondsSinceEpoch}',
      productId: widget.product.id,
      productName: widget.product.name,
      quantity: 1,
      unitPrice: unitPrice,
      totalPrice: unitPrice,
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
