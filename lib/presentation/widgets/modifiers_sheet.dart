import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product_dto.dart';
import '../../../data/models/order_dto.dart';
import '../../../data/models/ingredient_dto.dart';
import '../../../core/utils/constants.dart';
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
  final Set<String> _selectedIngredients = <String>{};
  final _notesController = TextEditingController();
  bool _isTakeaway = false;

  /// Categorías que usan la lista global de ingredientes (bocadillos/medios).
  bool get _usesSharedIngredients {
    final cats = ref.read(categoriesProvider).valueOrNull;
    final name = cats
            ?.where((c) => c.id == widget.product.categoryId)
            .map((c) => c.name)
            .firstOrNull ??
        '';
    return Constants.usesSharedIngredients(widget.product.categoryId, name);
  }

  /// Modificadores propios del producto, excluyendo los "extras" antiguos
  /// cuando se usa la lista global para no duplicar ingredientes.
  List<ModifierDefinition> get _productMods => widget.product.modifiers
      .where((m) => !(_usesSharedIngredients && m.modifierId == 'extras'))
      .toList();

  @override
  void initState() {
    super.initState();
    for (final mod in _productMods) {
      if (mod.multi) {
        _selectedMulti[mod.modifierId] = {};
      } else {
        _selectedOptions[mod.modifierId] =
            mod.options.isNotEmpty ? mod.options.first : null;
      }
    }
  }

  /// Precio total con extras/ingredientes seleccionados.
  double _totalWithMods(List<IngredientEntity> ingredients) {
    var total = widget.product.basePrice;
    for (final opt in _selectedOptions.values) {
      if (opt != null) total += opt.priceDelta;
    }
    for (final entry in _selectedMulti.entries) {
      final matches = _productMods.where((m) => m.modifierId == entry.key);
      if (matches.isEmpty) continue;
      final mod = matches.first;
      for (final opt in mod.options) {
        if (entry.value.contains(opt.optionId)) total += opt.priceDelta;
      }
    }
    for (final ing in ingredients) {
      if (_selectedIngredients.contains(ing.id)) total += ing.price;
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
    final ingredients =
        ref.watch(ingredientsProvider).valueOrNull ?? const <IngredientEntity>[];
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
                    ..._productMods.map((mod) {
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
                    if (_usesSharedIngredients && ingredients.isNotEmpty) ...[
                      const Text('Ingredientes extra',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 8,
                        children: ingredients.map((ing) {
                          final isSelected =
                              _selectedIngredients.contains(ing.id);
                          return FilterChip(
                            label: Text(
                                '${ing.name} ${ing.price > 0 ? "+${Formatters.currency(ing.price)}" : ""}'),
                            selected: isSelected,
                            onSelected: (_) => setState(() {
                              if (isSelected) {
                                _selectedIngredients.remove(ing.id);
                              } else {
                                _selectedIngredients.add(ing.id);
                              }
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
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
                  onPressed: () => _addOrderItem(ingredients),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text('Añadir ${Formatters.currency(_totalWithMods(ingredients))}'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addOrderItem(List<IngredientEntity> ingredients) {
    final modifiers = <AppliedModifier>[];
    _selectedOptions.forEach((modId, opt) {
      if (opt != null) {
        final matches = _productMods.where((m) => m.modifierId == modId);
        if (matches.isEmpty) return;
        modifiers.add(AppliedModifier(
          modifierId: modId,
          modifierName: matches.first.name,
          optionId: opt.optionId,
          optionName: opt.name,
          additionalPrice: opt.priceDelta,
        ));
      }
    });
    for (final entry in _selectedMulti.entries) {
      final matches = _productMods.where((m) => m.modifierId == entry.key);
      if (matches.isEmpty) continue;
      final mod = matches.first;
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
    // Ingredientes globales seleccionados
    for (final ing in ingredients) {
      if (_selectedIngredients.contains(ing.id)) {
        modifiers.add(AppliedModifier(
          modifierId: 'extras',
          modifierName: 'Extras',
          optionId: ing.id,
          optionName: ing.name,
          additionalPrice: ing.price,
        ));
      }
    }
    // El precio unitario incluye los extras: así subtotal y tickets cobran bien
    final unitPrice = _totalWithMods(ingredients);

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
