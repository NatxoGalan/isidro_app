import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/constants.dart';
import '../../data/models/order_dto.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/table_repository.dart';
import '../providers/auth_provider.dart';

class CartNotifier extends StateNotifier<CartState> {
  final OrderRepository _orderRepository;
  final TableRepository _tableRepository;
  String? _currentOrderId;
  StreamSubscription<OrderEntity?>? _orderSubscription;
  String? _watchedOrderId;
  int _resubAttempts = 0;

  CartNotifier(this._orderRepository, this._tableRepository) : super(const CartState());

  String? get currentOrderId => _currentOrderId;

  /// Items con cantidad pendiente de enviar a cocina.
  List<OrderItemEntity> get unsentItems =>
      state.items.where((i) => i.unsentQuantity > 0).toList();

  /// Marca todo lo actual como enviado a cocina (tras imprimir el delta).
  Future<void> markItemsSent() async {
    if (state.items.every((i) => i.unsentQuantity == 0)) return;
    state = state.copyWith(
      items: state.items
          .map((i) => i.copyWith(sentQuantity: i.quantity))
          .toList(),
    );
    await _saveDraft();
  }

  void addItem(OrderItemEntity item) {
    final existingIndex = state.items.indexWhere(
      (i) => i.productId == item.productId &&
          _modifiersMatch(i.modifiers, item.modifiers) &&
          i.notes == item.notes,
    );
    if (existingIndex >= 0) {
      final updated = List<OrderItemEntity>.from(state.items);
      updated[existingIndex] = updated[existingIndex].copyWith(
        quantity: updated[existingIndex].quantity + item.quantity,
      );
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(items: [...state.items, item]);
    }
    _saveDraft();
  }

  void removeItem(String itemId) {
    state = state.copyWith(
      items: state.items.where((i) => i.itemId != itemId).toList(),
    );
    _saveDraft();
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    state = state.copyWith(
      items: state.items.map((i) =>
        i.itemId == itemId ? i.copyWith(quantity: quantity) : i
      ).toList(),
    );
    _saveDraft();
  }

  void updateItemNotes(String itemId, String notes) {
    state = state.copyWith(
      items: state.items.map((i) =>
        i.itemId == itemId ? i.copyWith(notes: notes) : i
      ).toList(),
    );
    _saveDraft();
  }

  void setTakeaway(bool value) {
    state = state.copyWith(isTakeaway: value);
    _saveDraft();
  }

  void setPrinterTarget(String target) {
    state = state.copyWith(printerTarget: target);
    _saveDraft();
  }

  void setKitchenNotes(String notes) {
    state = state.copyWith(kitchenNotes: notes);
    _saveDraft();
  }

  /// Abre una mesa: carga borrador existente desde Firestore o empieza vacío.
  /// Además se suscribe en vivo: lo que añada otro dispositivo aparece solo.
  Future<void> setTable(String? tableId, String? tableNumber, {String? existingOrderId}) async {
    if (tableId == state.tableId) {
      ensureWatching();
      return;
    }
    await _stopWatching();

    if (existingOrderId != null && existingOrderId.isNotEmpty) {
      _currentOrderId = existingOrderId;
      await _loadDraft(existingOrderId);
      state = state.copyWith(tableId: tableId, tableNumber: tableNumber);
      _startOrderWatch(existingOrderId);
    } else {
      _currentOrderId = null;
      state = CartState(tableId: tableId, tableNumber: tableNumber);
    }
  }

  /// (Re)inicia la escucha en vivo de la orden con reintento si falla.
  void _startOrderWatch(String orderId) {
    _orderSubscription?.cancel();
    _watchedOrderId = orderId;
    _resubAttempts = 0;
    _orderSubscription = _orderRepository.watchOrder(orderId).listen(
          _onRemoteOrder,
          onError: (_) => _scheduleResubscribe(),
          onDone: () => _scheduleResubscribe(),
        );
  }

  void _scheduleResubscribe() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
    if (_watchedOrderId == null ||
        _watchedOrderId != _currentOrderId ||
        _resubAttempts >= 5) {
      return;
    }
    final delay = Duration(seconds: 2 << _resubAttempts); // 2,4,8,16,32s
    _resubAttempts++;
    Future.delayed(delay, () {
      if (_watchedOrderId != null &&
          _watchedOrderId == _currentOrderId &&
          _orderSubscription == null &&
          mounted) {
        _startOrderWatch(_watchedOrderId!);
      }
    });
  }

  /// Garantiza escucha activa (al reabrir la misma mesa o volver a la app).
  void ensureWatching() {
    final id = _currentOrderId;
    if (id == null || id.isEmpty || _orderSubscription != null) return;
    _resubAttempts = 0;
    _startOrderWatch(id);
  }

  Future<void> _stopWatching() async {
    await _orderSubscription?.cancel();
    _orderSubscription = null;
    _watchedOrderId = null;
    _resubAttempts = 0;
  }

  /// Lectura fresca puntual (p. ej. antes de imprimir el delta).
  Future<void> refreshFromServer() async {
    final id = _currentOrderId;
    if (id == null || id.isEmpty) return;
    try {
      final order = await _orderRepository
          .watchOrder(id)
          .first
          .timeout(const Duration(seconds: 5));
      if (order != null) _applyRemoteOrder(order);
    } catch (_) {}
  }

  /// Carga un borrador desde Firestore (draft o pendiente de cocina).
  Future<void> _loadDraft(String orderId) async {
    try {
      final stream = _orderRepository.watchOrder(orderId);
      final order = await stream.first;
      if (order != null) {
        _applyRemoteOrder(order);
      }
    } catch (_) {
      state = const CartState();
    }
  }

  /// Llega un cambio remoto de la orden (otro dispositivo).
  /// Se adopta si difiere del local; el eco del propio guardado es
  /// idéntico y se ignora, así no hay bucles.
  void _onRemoteOrder(OrderEntity? order) {
    if (order == null) return;
    if (order.status == OrderStatus.paid ||
        order.status == OrderStatus.cancelled) {
      return;
    }
    _applyRemoteOrder(order);
  }

  void _applyRemoteOrder(OrderEntity order) {
    final remoteSig = _itemsSignature(order.items);
    final localSig = _itemsSignature(state.items);
    final sameNotes = state.kitchenNotes == order.cashierNotes;
    final sameTakeaway = state.isTakeaway == order.isTakeaway;
    final sameTarget = state.printerTarget == order.printerTarget.name;
    if (remoteSig == localSig && sameNotes && sameTakeaway && sameTarget) {
      return;
    }
    state = state.copyWith(
      items: order.items,
      isTakeaway: order.isTakeaway,
      printerTarget: order.printerTarget.name,
      kitchenNotes: order.cashierNotes,
    );
  }

  String _itemsSignature(List<OrderItemEntity> items) {
    return items.map((i) => i.toMap().toString()).join('|');
  }

  /// Guarda borrador en Firestore
  Future<void> _saveDraft() async {
    if (state.tableId == null) return;

    // Si la mesa queda sin items, borrar borrador y liberar
    if (state.isEmpty) {
      try {
        if (_currentOrderId != null && _currentOrderId!.isNotEmpty) {
          await _orderRepository.deleteOrder(_currentOrderId!);
          _currentOrderId = null;
        }
        await _tableRepository.updateTable(state.tableId!, {'hasItems': false});
      } catch (_) {}
      return;
    }

    final order = OrderEntity(
      id: _currentOrderId ?? '',
      venueId: Constants.defaultVenueId,
      tableId: state.tableId!,
      status: OrderStatus.draft,
      items: state.items,
      printerTarget: state.printerTarget == 'both'
          ? PrinterTarget.both
          : state.printerTarget == 'kitchen'
              ? PrinterTarget.kitchen
              : PrinterTarget.bar,
      cashierNotes: state.kitchenNotes,
      isTakeaway: state.isTakeaway,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (_currentOrderId != null && _currentOrderId!.isNotEmpty) {
        await _orderRepository.updateOrder(_currentOrderId!, order.toFirestore());
      } else {
        final orderId = await _orderRepository.createOrder(order);
        _currentOrderId = orderId;
        if (state.tableId != null) {
          await _tableRepository.openTable(state.tableId!, DateTime.now());
          await _tableRepository.assignOrder(state.tableId!, orderId);
        }
      }
      // Marcar que la mesa tiene items
      if (state.tableId != null) {
        await _tableRepository.updateTable(state.tableId!, {'hasItems': true});
      }
    } catch (_) {}
  }

  /// Envía a cocina: actualiza borrador a pending
  Future<void> sendToKitchen() async {
    if (_currentOrderId == null || state.isEmpty) return;

    try {
      await _orderRepository.updateOrder(_currentOrderId!, {
        'status': Constants.orderPending,
        'sentToKitchenAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    } catch (_) {}
  }

  /// Cierra la mesa: marca como paid y libera
  Future<void> closeTable() async {
    await _stopWatching();
    if (_currentOrderId != null) {
      try {
        await _orderRepository.updateOrder(_currentOrderId!, {
          'status': Constants.orderPaid,
          'updatedAt': DateTime.now(),
        });
      } catch (_) {}
    }
    if (state.tableId != null) {
      try {
        await _tableRepository.closeTable(state.tableId!);
        await _tableRepository.updateTable(state.tableId!, {'hasItems': false});
      } catch (_) {}
    }
    _currentOrderId = null;
    state = const CartState();
  }

  Future<void> clear() async {
    await _stopWatching();
    _currentOrderId = null;
    state = const CartState();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  double get subtotal => state.items.fold(0, (sum, item) => sum + (item.unitPrice * item.quantity));
  double get total => subtotal;
  int get itemCount => state.items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => state.items.isEmpty;
}

class CartState {
  final List<OrderItemEntity> items;
  final String? tableId;
  final String? tableNumber;
  final bool isTakeaway;
  final String printerTarget;
  final String kitchenNotes;

  const CartState({
    this.items = const [],
    this.tableId,
    this.tableNumber,
    this.isTakeaway = false,
    this.printerTarget = 'both',
    this.kitchenNotes = '',
  });

  CartState copyWith({
    List<OrderItemEntity>? items,
    String? tableId,
    String? tableNumber,
    bool? isTakeaway,
    String? printerTarget,
    String? kitchenNotes,
  }) {
    return CartState(
      items: items ?? this.items,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      isTakeaway: isTakeaway ?? this.isTakeaway,
      printerTarget: printerTarget ?? this.printerTarget,
      kitchenNotes: kitchenNotes ?? this.kitchenNotes,
    );
  }

  double get subtotal => items.fold(0, (sum, item) => sum + (item.unitPrice * item.quantity));
  double get total => subtotal;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
}

bool _modifiersMatch(List<AppliedModifier> a, List<AppliedModifier> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i].modifierId != b[i].modifierId || a[i].optionId != b[i].optionId) {
      return false;
    }
  }
  return true;
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(
    ref.read(orderRepositoryProvider),
    ref.read(tableRepositoryProvider),
  );
});
