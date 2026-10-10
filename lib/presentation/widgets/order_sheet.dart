import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../data/models/order_dto.dart';
import '../../data/models/print_dto.dart';
import '../../services/esc_pos_generator.dart';
import '../../core/utils/formatters.dart';
import '../providers/cart_provider.dart';
import '../providers/printer_provider.dart';
import 'payment_sheet.dart';

class OrderSheet extends ConsumerStatefulWidget {
  final List<OrderItemEntity> items;
  final double subtotal;
  final double total;
  final String notes;
  final ValueChanged<String> onNotesChanged;
  final String? tableNumber;

  const OrderSheet({
    super.key,
    required this.items,
    required this.subtotal,
    required this.total,
    required this.notes,
    required this.onNotesChanged,
    this.tableNumber,
  });

  @override
  ConsumerState<OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends ConsumerState<OrderSheet> {
  late final TextEditingController _notesController;
  final FocusNode _notesFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.notes);
  }

  @override
  void didUpdateWidget(covariant OrderSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_notesFocus.hasFocus && _notesController.text != widget.notes) {
      _notesController.text = widget.notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final subtotal = widget.subtotal;
    final total = widget.total;
    final onNotesChanged = widget.onNotesChanged;
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Añadir productos'),
              onPressed: () {},
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return _OrderItemRow(item: item);
              },
            ),
          ),
          const Divider(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _notesController,
              focusNode: _notesFocus,
              onChanged: onNotesChanged,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notas generales de la comanda',
                hintText: 'Ej: alérgico a frutos secos, sin gluten...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.note_alt_outlined, color: AppTheme.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Subtotal', style: TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
                  Text(Formatters.currency(subtotal), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(Formatters.currency(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.print, color: AppTheme.warning),
                    label: const Text('Enviar a cocina', style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w600)),
                    onPressed: () => _sendToKitchen(context, ref),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppTheme.warning, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.payment),
                    label: const Text('Cerrar y pagar'),
                    onPressed: () => _showPaymentSheet(context, ref),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendToKitchen(BuildContext context, WidgetRef ref) async {
    final cart = ref.read(cartProvider);
    final tableNum = widget.tableNumber ?? 'Mesa';

    // 1. Actualizar borrador a pending en Firestore
    await ref.read(cartProvider.notifier).sendToKitchen();

    // 2. Generar ticket ESC/POS
    final itemNotesList = widget.items
        .where((i) => i.notes.isNotEmpty)
        .map((i) => '${i.productName}: ${i.notes}')
        .toList();
    final allItemNotes = itemNotesList.join('\n');
    
    final combinedNotes = [
      if (widget.notes.isNotEmpty) widget.notes,
      if (cart.kitchenNotes.isNotEmpty) cart.kitchenNotes,
      if (allItemNotes.isNotEmpty) '--- Notas por plato ---\n$allItemNotes',
    ].join('\n');
    
    final escPosBytes = EscPosGenerator.generateKitchenTicket(
      orderId: ref.read(cartProvider.notifier).currentOrderId ?? 'draft',
      tableNumber: tableNum,
      items: widget.items.map((i) => i.toOrderItemData()).toList(),
      notes: combinedNotes.isNotEmpty ? combinedNotes : null,
      kitchenNotes: null,
      createdAt: DateTime.now(),
    );
    
    final escPosHex = EscPosGenerator.bytesToHex(escPosBytes);
    
    final printItems = widget.items.map((i) => PrintItemData(
      productId: i.productId,
      name: i.productName,
      quantity: i.quantity,
      unitPrice: i.unitPrice,
      modifiers: i.modifiers.map((m) => m.optionName ?? m.modifierName).toList(),
      notes: i.notes,
      isTakeaway: i.isTakeaway,
    )).toList();

    ref.read(printQueueProvider.notifier).addTicket(
      orderId: ref.read(cartProvider.notifier).currentOrderId ?? 'draft',
      tableNumber: tableNum,
      type: PrintType.kitchen,
      items: printItems,
      notes: combinedNotes.isNotEmpty ? combinedNotes : null,
      escPosHex: escPosHex,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Comanda enviada a cocina'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPaymentSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => PaymentSheet(
        total: widget.total,
        items: widget.items,
        tableNumber: widget.tableNumber ?? '',
        onPaid: (paymentMethod) async {
          // Generar ticket de cuenta
          final escPosBytes = EscPosGenerator.generateBillTicket(
            orderId: ref.read(cartProvider.notifier).currentOrderId ?? 'bill',
            tableNumber: widget.tableNumber ?? 'Mesa',
            items: widget.items.map((i) => i.toOrderItemData()).toList(),
            subtotal: widget.subtotal,
            tax: 0,
            total: widget.total,
            paymentMethod: paymentMethod,
            createdAt: DateTime.now(),
          );
          
          final escPosHex = EscPosGenerator.bytesToHex(escPosBytes);

          // Añadir ticket de cuenta a cola de impresión
          final printItems = widget.items.map((i) => PrintItemData(
            productId: i.productId,
            name: i.productName,
            quantity: i.quantity,
            unitPrice: i.unitPrice,
            modifiers: i.modifiers.map((m) => m.optionName ?? m.modifierName).toList(),
            notes: i.notes,
            isTakeaway: i.isTakeaway,
          )).toList();

          ref.read(printQueueProvider.notifier).addTicket(
            orderId: ref.read(cartProvider.notifier).currentOrderId ?? 'bill',
            tableNumber: widget.tableNumber ?? 'Mesa',
            type: PrintType.bill,
            items: printItems,
            notes: paymentMethod,
            escPosHex: escPosHex,
          );

          // Pagar y liberar mesa en Firestore
          await ref.read(cartProvider.notifier).closeTable();
          
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pago completado con $paymentMethod. Mesa liberada'),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }
}

class _OrderItemRow extends ConsumerStatefulWidget {
  final OrderItemEntity item;
  const _OrderItemRow({required this.item});

  @override
  ConsumerState<_OrderItemRow> createState() => _OrderItemRowState();
}

class _OrderItemRowState extends ConsumerState<_OrderItemRow> {
  late final TextEditingController _notesController;
  final FocusNode _notesFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.item.notes);
  }

  @override
  void didUpdateWidget(covariant _OrderItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_notesFocus.hasFocus &&
        _notesController.text != widget.item.notes) {
      _notesController.text = widget.item.notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
              Text(Formatters.currency(item.totalPrice * item.quantity), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _notesController,
            focusNode: _notesFocus,
            onChanged: (v) => ref.read(cartProvider.notifier).updateItemNotes(item.itemId, v),
            decoration: InputDecoration(
              hintText: ' Ej: sin cebolla, poco hecho...',
              hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.note_alt_outlined, size: 16, color: AppTheme.textSecondary),
              prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 0),
            ),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary), onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.itemId, item.quantity - 1), constraints: const BoxConstraints(minWidth: 40, minHeight: 40)),
              Text('${item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              IconButton(icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary), onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.itemId, item.quantity + 1), constraints: const BoxConstraints(minWidth: 40, minHeight: 40)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.error), onPressed: () => ref.read(cartProvider.notifier).removeItem(item.itemId), constraints: const BoxConstraints(minWidth: 40, minHeight: 40)),
            ],
          ),
        ],
      ),
    );
  }
}
