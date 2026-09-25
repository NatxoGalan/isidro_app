import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/constants.dart';
import '../../data/models/category_dto.dart';
import '../../data/models/order_dto.dart';
import '../../data/models/print_dto.dart';
import '../../data/models/print_job_dto.dart';
import '../../data/models/printer_dto.dart';
import '../../services/esc_pos_generator.dart';
import '../../services/printer_service.dart';
import '../../services/print_station.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/printer_provider.dart';
import '../widgets/product_search_bar.dart';
import '../widgets/category_chips.dart';
import '../widgets/product_picker_card.dart';

class TableDetailScreen extends ConsumerStatefulWidget {
  final String tableId;
  const TableDetailScreen({super.key, required this.tableId});

  @override
  ConsumerState<TableDetailScreen> createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends ConsumerState<TableDetailScreen>
    with WidgetsBindingObserver {
  String _selectedCategory = 'Todos';
  String _searchQuery = '';
  bool _showProductPicker = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(cartProvider.notifier).ensureWatching();
    }
  }

  /// true si el item es de bebidas/varios/cafetería (ticket separado).
  bool _isDrinks(OrderItemEntity i) =>
      Constants.drinksCategoryIds.contains(i.categoryId);

  /// Slug (id) de la categoría seleccionada, resuelto desde Firestore.
  String _slugFor(List<CategoryEntity>? categories, String name) {
    if (name == 'Todos') return '';
    if (categories == null) return '';
    for (final c in categories) {
      if (c.name == name) return c.id;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final tableNumber = cart.tableNumber ?? widget.tableId;
    final hasItems = cart.items.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cart, tableNumber, hasItems),
            Expanded(
              child: _showProductPicker
                  ? _buildProductPicker()
                  : hasItems
                      ? _buildCartView(cart, tableNumber)
                      : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CartState cart, String tableNumber, bool hasItems) {
    final itemCount = cart.itemCount;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.systemBackground.withValues(alpha: 0.85),
            border: const Border(bottom: BorderSide(color: AppColors.separator, width: 0.5)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.gray5,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.blue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Mesa $tableNumber',
                              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.label),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: hasItems ? AppColors.orange.withValues(alpha: 0.12) : AppColors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                hasItems ? '$itemCount items' : 'Abierta',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: hasItems ? AppColors.orange : AppColors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasItems
                              ? '${cart.itemCount} productos · ${Formatters.currency(cart.subtotal)}'
                              : 'Sin productos aún',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.secondaryLabel),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showProductPicker = true),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_rounded, size: 56, color: AppColors.blue.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              'Comanda vacía',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.label),
            ),
            const SizedBox(height: 6),
            Text(
              'Añade productos para empezar',
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.secondaryLabel),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text('Añadir productos', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                onPressed: () => setState(() => _showProductPicker = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartView(CartState cart, String tableNumber) {
    final unsentCount =
        cart.items.fold<int>(0, (s, i) => s + i.unsentQuantity);
    return Column(
      children: [
        // Items list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: cart.items.length,
            separatorBuilder: (_, _) => Container(
              height: 0.5,
              color: AppColors.separator,
              margin: const EdgeInsets.only(left: 16),
            ),
            itemBuilder: (context, index) {
              final item = cart.items[index];
              return _CartItemCard(item: item);
            },
          ),
        ),
        // Notes
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: TextEditingController(text: cart.kitchenNotes),
            onChanged: (v) => ref.read(cartProvider.notifier).setKitchenNotes(v),
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.label),
            decoration: InputDecoration(
              hintText: 'Notas generales...',
              hintStyle: GoogleFonts.inter(color: AppColors.gray2, fontSize: 14),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.separator, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.separator, width: 0.5),
              ),
              prefixIcon: const Icon(Icons.note_alt_outlined, size: 18, color: AppColors.gray2),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        // Total
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.separator.withValues(alpha: 0.5), width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.label)),
              Text(Formatters.currency(cart.total), style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.green)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: Icon(
                        unsentCount > 0
                            ? Icons.print_rounded
                            : Icons.check_circle_rounded,
                        size: 18),
                    label: Text(
                        unsentCount > 0
                            ? 'Cocina ($unsentCount)'
                            : 'Enviado ✓',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    onPressed: () => _sendToKitchen(cart, tableNumber),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.orange,
                      backgroundColor: AppColors.orange.withValues(alpha: 0.08),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_rounded, size: 18),
                    label: Text('Proforma', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                    onPressed: () => _printProforma(cart, tableNumber),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.blue,
                      backgroundColor: AppColors.blue.withValues(alpha: 0.08),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.payment_rounded, size: 18),
                    label: Text('Cerrar y pagar', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                    onPressed: () => _closeAndPay(cart, tableNumber),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Add more
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Añadir más', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
              onPressed: () => setState(() => _showProductPicker = true),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue,
                backgroundColor: AppColors.blue.withValues(alpha: 0.06),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductPicker() {
    final productsAsync = ref.watch(productsProvider);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.separator, width: 0.5)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showProductPicker = false),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.gray5,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.blue),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ProductSearchBar(
                      query: _searchQuery,
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final cats = ref.watch(categoriesProvider).valueOrNull;
                  final labels = [
                    'Todos',
                    if (cats != null)
                      ...cats.map((c) => c.name)
                    else
                      ...const [
                        'Tapas',
                        'Bocadillos',
                        'Bebidas',
                        'Varios',
                        'Cafetería'
                      ],
                  ];
                  final selected = labels.contains(_selectedCategory)
                      ? _selectedCategory
                      : 'Todos';
                  return CategoryChips(
                    categories: labels,
                    selected: selected,
                    onChanged: (c) => setState(() => _selectedCategory = c),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: productsAsync.when(
            data: (products) {
              final cats = ref.watch(categoriesProvider).valueOrNull;
              final slug = _slugFor(cats, _selectedCategory);
              final filtered = products.where((p) {
                final matchesCategory = _selectedCategory == 'Todos' || p.categoryId == slug;
                final matchesSearch = _searchQuery.isEmpty || p.name.toLowerCase().contains(_searchQuery.toLowerCase());
                return matchesCategory && matchesSearch;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text('No hay productos', style: GoogleFonts.inter(color: AppColors.secondaryLabel, fontSize: 15)),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final p = filtered[index];
                  return ProductPickerCard(
                    product: p,
                    onAdd: () {
                      ref.read(cartProvider.notifier).addItem(OrderItemEntity(
                        itemId: 'item_${DateTime.now().millisecondsSinceEpoch}',
                        productId: p.id,
                        productName: p.name,
                        quantity: 1,
                        unitPrice: p.basePrice,
                        totalPrice: p.basePrice,
                        modifiers: [],
                        notes: '',
                        isTakeaway: false,
                        status: OrderItemStatus.pending,
                        createdAt: DateTime.now(),
                        categoryId: p.categoryId,
                        categoryName: cats
                            ?.where((c) => c.id == p.categoryId)
                            .map((c) => c.name)
                            .firstOrNull ??
                            '',
                      ));
                      setState(() => _showProductPicker = false);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.blue)),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  void _sendToKitchen(CartState cart, String tableNumber) async {
    if (cart.isEmpty) return;

    final notifier = ref.read(cartProvider.notifier);
    // Leer estado fresco de Firestore: evita reimprimir por copia desactualizada
    await notifier.refreshFromServer();
    if (!mounted) return;
    final fresh = ref.read(cartProvider);
    if (fresh.isEmpty) return;

    // Solo lo nuevo: lo ya enviado no se reimprime
    final deltas =
        fresh.items.where((i) => i.unsentQuantity > 0).toList();
    if (deltas.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nada nuevo que enviar a cocina')),
        );
      }
      return;
    }

    final waiterName = ref.read(authProvider).value?.displayName;
    final orderId = notifier.currentOrderId ?? 'draft';
    final now = DateTime.now();

    // Partir en grupos: comida y bebidas salen en tickets separados
    // (ambos a las impresoras de Cocina) para no mezclar.
    final food = deltas.where((i) => !_isDrinks(i)).toList();
    final drinks = deltas.where(_isDrinks).toList();

    List<OrderItemData> toTicketData(List<OrderItemEntity> group) {
      return group
          .map((i) => OrderItemData(
                name: i.productName,
                quantity: i.unsentQuantity,
                unitPrice: i.unitPrice,
                modifiers: i.modifiers
                    .map((m) => ModifierData(
                          name: m.optionName ?? m.modifierName,
                          price: m.additionalPrice,
                        ))
                    .toList(),
                notes: i.notes,
                isTakeaway: i.isTakeaway,
              ))
          .toList();
    }

    String groupNotes(List<OrderItemEntity> group) {
      final itemNotes = group
          .where((i) => i.notes.isNotEmpty)
          .map((i) => '${i.productName}: ${i.notes}')
          .join('\n');
      return [
        if (fresh.kitchenNotes.isNotEmpty) fresh.kitchenNotes,
        if (itemNotes.isNotEmpty) '--- Notas por plato ---\n$itemNotes',
      ].join('\n');
    }

    List<PrintItemData> toHistoryData(List<OrderItemEntity> group) {
      return group
          .map((i) => PrintItemData(
                productId: i.productId,
                name: i.productName,
                quantity: i.unsentQuantity,
                unitPrice: i.unitPrice,
                modifiers: i.modifiers
                    .map((m) => m.optionName ?? m.modifierName)
                    .toList(),
                notes: i.notes,
                isTakeaway: i.isTakeaway,
              ))
          .toList();
    }

    // Un ticket por grupo no vacío
    final groups = <({String label, List<OrderItemEntity> items})>[
      if (food.isNotEmpty) (label: '', items: food),
      if (drinks.isNotEmpty) (label: 'BEBIDAS', items: drinks),
    ];
    final tickets = <({String label, List<int> bytes, String hex})>[];
    for (final g in groups) {
      final notes = groupNotes(g.items);
      final bytes = EscPosGenerator.generateKitchenTicket(
        orderId: orderId,
        tableNumber: tableNumber,
        items: toTicketData(g.items),
        notes: notes.isNotEmpty ? notes : null,
        kitchenNotes: null,
        waiterName: waiterName,
        stationLabel: g.label.isNotEmpty ? g.label : null,
        createdAt: now,
      );
      tickets.add((
        label: g.label,
        bytes: bytes,
        hex: EscPosGenerator.bytesToHex(bytes),
      ));
      ref.read(printQueueProvider.notifier).addTicket(
            orderId: orderId,
            tableNumber: tableNumber,
            type: PrintType.kitchen,
            items: toHistoryData(g.items),
            notes: notes.isNotEmpty ? notes : null,
            escPosHex: EscPosGenerator.bytesToHex(bytes),
          );
    }

    // Modo pruebas: simular sin tocar red ni relay
    if (ref.read(isTestModeProvider)) {
      await notifier.markItemsSent();
      await notifier.sendToKitchen();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modo pruebas: comanda simulada (sin imprimir)'),
          ),
        );
      }
      return;
    }

    // 1) Intento directo (instantáneo si este móvil tiene WiFi)
    final allPrinters = ref.read(printersProvider).value ?? [];
    final targets =
        printersForWorkspace(allPrinters, PrinterWorkspace.kitchen);

    var directOk = 0;
    var targetCount = 0;
    var queued = 0;
    String? deviceId;
    for (final t in tickets) {
      for (final p in targets) {
        targetCount++;
        // ignore: use_build_context_synchronously
        if (await PrinterService.printBytes(p, t.bytes)) {
          directOk++;
        } else {
          // 2) Lo que no sale directo se encola: lo imprime la tablet con WiFi
          try {
            deviceId ??= await getDeviceId();
            await ref.read(printerRepositoryProvider).enqueueJob(
                  venueId: Constants.defaultVenueId,
                  printerId: p.id,
                  printerName:
                      t.label.isNotEmpty ? '${p.name} (${t.label})' : p.name,
                  workspace: PrinterWorkspace.kitchen,
                  type: PrintJobType.kitchen,
                  tableNumber: tableNumber,
                  escPosHex: t.hex,
                  createdBy: deviceId,
                );
            queued++;
          } catch (_) {}
        }
      }
      if (targets.isEmpty) {
        try {
          deviceId ??= await getDeviceId();
          await ref.read(printerRepositoryProvider).enqueueJob(
                venueId: Constants.defaultVenueId,
                printerId: '',
                printerName:
                    t.label.isNotEmpty ? 'Cocina (${t.label})' : 'Cocina',
                workspace: PrinterWorkspace.kitchen,
                type: PrintJobType.kitchen,
                tableNumber: tableNumber,
                escPosHex: t.hex,
                createdBy: deviceId,
              );
          queued++;
        } catch (_) {}
      }
    }

    // Marcar como enviado + orden a pendiente (aunque vaya por relay)
    await notifier.markItemsSent();
    await notifier.sendToKitchen();

    final groupWord =
        groups.map((g) => g.label.isNotEmpty ? g.label : 'cocina').join(' + ');
    String message;
    Color bg;
    if (directOk == targetCount && targetCount > 0) {
      message =
          'Comanda ($groupWord) impresa en ${targets.map((p) => p.name).join(', ')}';
      bg = AppColors.green;
    } else if (queued > 0) {
      message =
          'Sin conexión directa: encolada ($groupWord), se imprimirá al recuperar WiFi';
      bg = AppColors.orange;
    } else if (directOk > 0) {
      message = 'Impresa en $directOk de $targetCount envíos';
      bg = AppColors.orange;
    } else {
      message = 'No se pudo enviar (revisa impresoras y conexión)';
      bg = AppColors.red;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: bg,
        ),
      );
    }
  }

  /// Imprime la factura proforma en la impresora principal SIN cerrar la mesa
  void _printProforma(CartState cart, String tableNumber) async {
    if (cart.isEmpty) return;

    final waiterName = ref.read(authProvider).value?.displayName;

    final escPosBytes = EscPosGenerator.generateBillTicket(
      orderId: ref.read(cartProvider.notifier).currentOrderId ?? 'bill',
      tableNumber: tableNumber,
      items: cart.items.map((i) => i.toOrderItemData()).toList(),
      subtotal: cart.subtotal,
      tax: 0,
      total: cart.total,
      waiterName: waiterName,
      createdAt: DateTime.now(),
    );

    final escPosHex = EscPosGenerator.bytesToHex(escPosBytes);

    final printItems = cart.items.map((i) => PrintItemData(
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
      tableNumber: tableNumber,
      type: PrintType.bill,
      items: printItems,
      escPosHex: escPosHex,
    );

    final allPrinters = ref.read(printersProvider).value ?? [];
    final principal = principalPrinter(allPrinters);

    final result = await _printOrEnqueue(
      bytes: escPosBytes,
      escPosHex: escPosHex,
      printer: principal,
      type: PrintJobType.bill,
      tableNumber: tableNumber,
    );

    String message;
    Color bg;
    switch (result) {
      case 'printed':
        message = 'Proforma impresa en ${principal!.name}';
        bg = AppColors.green;
        break;
      case 'queued':
        message = 'Sin conexión directa: proforma encolada, se imprimirá sola';
        bg = AppColors.orange;
        break;
      case 'simulated':
        message = 'Modo pruebas: proforma simulada (sin imprimir)';
        bg = AppColors.blue;
        break;
      default:
        message = 'No se pudo imprimir la proforma';
        bg = AppColors.red;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: bg),
      );
    }
  }

  /// Intenta impresión directa en [printer]; si falla o no hay,
  /// encola el trabajo para la estación (relay).
  /// Devuelve 'printed', 'queued' o 'failed'.
  Future<String> _printOrEnqueue({
    required List<int> bytes,
    required String escPosHex,
    PrinterEntity? printer,
    String workspace = '',
    required String type,
    required String tableNumber,
  }) async {
    if (ref.read(isTestModeProvider)) return 'simulated';
    if (printer != null) {
      if (await PrinterService.printBytes(printer, bytes)) return 'printed';
    }
    try {
      final deviceId = await getDeviceId();
      await ref.read(printerRepositoryProvider).enqueueJob(
            venueId: Constants.defaultVenueId,
            printerId: printer?.id ?? '',
            printerName: printer?.name ?? '',
            workspace: workspace,
            type: type,
            tableNumber: tableNumber,
            escPosHex: escPosHex,
            createdBy: deviceId,
          );
      return 'queued';
    } catch (_) {
      return 'failed';
    }
  }

  void _closeAndPay(CartState cart, String tableNumber) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PaymentSheet(
        total: cart.total,
        items: cart.items,
        tableNumber: tableNumber,
        subtotal: cart.subtotal,
        onPaid: (paymentMethod) async {
          final waiterName = ref.read(authProvider).value?.displayName;

          final escPosBytes = EscPosGenerator.generateBillTicket(
            orderId: ref.read(cartProvider.notifier).currentOrderId ?? 'bill',
            tableNumber: tableNumber,
            items: cart.items.map((i) => i.toOrderItemData()).toList(),
            subtotal: cart.subtotal,
            tax: 0,
            total: cart.total,
            paymentMethod: paymentMethod,
            waiterName: waiterName,
            createdAt: DateTime.now(),
          );

          final escPosHex = EscPosGenerator.bytesToHex(escPosBytes);

          final printItems = cart.items.map((i) => PrintItemData(
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
            tableNumber: tableNumber,
            type: PrintType.bill,
            items: printItems,
            notes: paymentMethod,
            escPosHex: escPosHex,
          );

          final allPrinters = ref.read(printersProvider).value ?? [];
          final principal = principalPrinter(allPrinters);
          final billResult = await _printOrEnqueue(
            bytes: escPosBytes,
            escPosHex: escPosHex,
            printer: principal,
            type: PrintJobType.bill,
            tableNumber: tableNumber,
          );

          await ref.read(cartProvider.notifier).closeTable();

          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(billResult == 'printed'
                    ? 'Pago completado. Cuenta impresa. Mesa liberada'
                    : billResult == 'queued'
                        ? 'Pago completado. Cuenta encolada, se imprimirá sola'
                        : billResult == 'simulated'
                            ? 'Pago completado (modo pruebas, sin imprimir)'
                            : 'Pago completado. Mesa liberada (cuenta no impresa)'),
                backgroundColor: billResult == 'failed'
                    ? AppColors.red
                    : billResult == 'printed'
                        ? AppColors.green
                        : billResult == 'simulated'
                            ? AppColors.blue
                            : AppColors.orange,
              ),
            );
          }
        },
      ),
    );
  }
}

// ── Cart Item Card ───────────────────────────────────────────────────
class _CartItemCard extends ConsumerWidget {
  final OrderItemEntity item;
  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineTotal = item.unitPrice * item.quantity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.label),
                ),
              ),
              if (item.unsentQuantity == 0)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.check_circle_rounded,
                      color: AppColors.green, size: 18),
                )
              else
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.unsentQuantity} nuevo${item.unsentQuantity == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange),
                  ),
                ),
              Text(
                Formatters.currency(lineTotal),
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.blue),
              ),
            ],
          ),
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.notes,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondaryLabel, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.gray6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: TextEditingController(text: item.notes),
                    onChanged: (v) => ref.read(cartProvider.notifier).updateItemNotes(item.itemId, v),
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.label),
                    decoration: InputDecoration(
                      hintText: 'Nota...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.gray2),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.note_alt_outlined, size: 14, color: AppColors.gray2),
                      prefixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // iOS-style stepper
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.gray6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StepperButton(
                      icon: Icons.remove_rounded,
                      onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.itemId, item.quantity - 1),
                    ),
                    SizedBox(
                      width: 32,
                      child: Center(
                        child: Text(
                          '${item.quantity}',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.label),
                        ),
                      ),
                    ),
                    _StepperButton(
                      icon: Icons.add_rounded,
                      onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.itemId, item.quantity + 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => ref.read(cartProvider.notifier).removeItem(item.itemId),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 18, color: AppColors.blue),
      ),
    );
  }
}

// ── Payment Sheet ────────────────────────────────────────────────────
class _PaymentSheet extends ConsumerStatefulWidget {
  final double total;
  final double subtotal;
  final Function(String paymentMethod) onPaid;
  final List<OrderItemEntity> items;
  final String tableNumber;

  const _PaymentSheet({
    required this.total,
    required this.subtotal,
    required this.onPaid,
    required this.items,
    required this.tableNumber,
  });

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  String _method = 'cash';
  String _cashInput = '';
  double _change = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.gray4,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Cobro', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.label)),
                const Spacer(),
                Text(Formatters.currency(widget.total), style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.green)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: AppColors.gray5, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close_rounded, size: 18, color: AppColors.gray1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Method selector
            Container(
              decoration: BoxDecoration(
                color: AppColors.gray6,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  _MethodOption(label: 'Efectivo', value: 'cash', selected: _method, onChanged: (v) => setState(() => _method = v)),
                  _MethodOption(label: 'Tarjeta', value: 'card', selected: _method, onChanged: (v) => setState(() => _method = v)),
                  _MethodOption(label: 'Invitación', value: 'invitation', selected: _method, onChanged: (v) => setState(() => _method = v)),
                ],
              ),
            ),
            if (_method == 'cash') ...[
              const SizedBox(height: 16),
              TextField(
                onChanged: (v) {
                  setState(() {
                    _cashInput = v;
                    final received = double.tryParse(v) ?? 0;
                    _change = received - widget.total;
                  });
                },
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.inter(fontSize: 16, color: AppColors.label),
                decoration: InputDecoration(
                  labelText: 'Importe recibido',
                  prefixText: '€ ',
                  labelStyle: GoogleFonts.inter(color: AppColors.secondaryLabel),
                ),
              ),
              if (_cashInput.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Cambio: ${Formatters.currency(_change)}',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _change >= 0 ? AppColors.green : AppColors.red,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _canPay() ? _confirmPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Confirmar pago', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  bool _canPay() {
    if (_method == 'cash') return _cashInput.isNotEmpty && (double.tryParse(_cashInput) ?? 0) >= widget.total;
    return true;
  }

  void _confirmPayment() {
    widget.onPaid(_method);
  }
}

class _MethodOption extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onChanged;

  const _MethodOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.label : AppColors.gray1,
            ),
          ),
        ),
      ),
    );
  }
}
