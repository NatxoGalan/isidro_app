import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/table_dto.dart';
import '../../data/repositories/table_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../providers/auth_provider.dart';

class TableNotifier extends StateNotifier<AsyncValue<List<TableEntity>>> {
  final TableRepository _tableRepository;
  final OrderRepository _orderRepository;
  StreamSubscription<List<TableEntity>>? _subscription;

  TableNotifier(this._tableRepository, this._orderRepository) : super(const AsyncValue.loading());

  /// Suscripción continua al stream de Firestore (real-time)
  void watchTables(String venueId) {
    _subscription?.cancel();
    state = const AsyncValue.loading();
    _subscription = _tableRepository.watchTables(venueId).listen(
      (tables) {
        if (mounted) {
          tables.sort((a, b) {
            final numA = int.tryParse(a.tableNumber) ?? 0;
            final numB = int.tryParse(b.tableNumber) ?? 0;
            return numA.compareTo(numB);
          });
          state = AsyncValue.data(tables);
        }
      },
      onError: (e) {
        if (mounted) state = AsyncValue.error(e, StackTrace.current);
      },
    );
  }

  TableEntity? getTableById(String tableId) {
    final stateValue = state.value;
    if (stateValue == null) return null;
    return stateValue.firstWhere((t) => t.id == tableId, orElse: () => throw Exception('Table not found'));
  }

  int get occupiedCount {
    final stateValue = state.value;
    if (stateValue == null) return 0;
    return stateValue.where((t) => t.isOccupied).length;
  }

  /// Mueve una mesa ocupada a otra libre
  Future<void> moveTable({
    required String fromTableId,
    required String toTableId,
  }) async {
    final fromTable = getTableById(fromTableId);
    final toTable = getTableById(toTableId);
    
    if (fromTable == null || toTable == null) return;
    if (fromTable.status != TableStatus.occupied || toTable.status != TableStatus.free) return;

    final orderId = fromTable.currentOrderId;
    if (orderId == null) return;

    await _tableRepository.moveTable(
      fromTableId: fromTableId,
      toTableId: toTableId,
      orderId: orderId,
    );
    // El stream real-time actualizará el estado automáticamente
  }

  /// Añade una mesa nueva
  Future<void> addTable({
    required String venueId,
    required String zoneId,
    required String tableNumber,
    required int capacity,
  }) async {
    await _tableRepository.addTable(
      venueId: venueId,
      zoneId: zoneId,
      tableNumber: tableNumber,
      capacity: capacity,
    );
    // El stream real-time actualizará el estado automáticamente
  }

  /// Elimina una mesa
  Future<void> deleteTable(String tableId) async {
    await _tableRepository.deleteTable(tableId);
    // El stream real-time actualizará el estado automáticamente
  }

  /// Junta dos mesas ocupadas en una
  Future<void> mergeTables({
    required String targetTableId,
    required String sourceTableId,
  }) async {
    final targetTable = getTableById(targetTableId);
    final sourceTable = getTableById(sourceTableId);
    
    if (targetTable == null || sourceTable == null) return;
    if (targetTable.status != TableStatus.occupied || sourceTable.status != TableStatus.occupied) return;

    final targetOrderId = targetTable.currentOrderId;
    final sourceOrderId = sourceTable.currentOrderId;
    
    if (targetOrderId == null || sourceOrderId == null) return;

    // 1. Fusionar los items de las órdenes
    await _orderRepository.mergeOrders(
      targetOrderId: targetOrderId,
      sourceOrderId: sourceOrderId,
    );

    // 2. Actualizar las mesas (liberar origen, mantener destino)
    await _tableRepository.mergeTables(
      targetTableId: targetTableId,
      sourceTableId: sourceTableId,
      targetOrderId: targetOrderId,
      sourceOrderId: sourceOrderId,
    );
    // El stream real-time actualizará el estado automáticamente
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final tableProvider = StateNotifierProvider<TableNotifier, AsyncValue<List<TableEntity>>>((ref) {
  return TableNotifier(
    ref.read(tableRepositoryProvider),
    ref.read(orderRepositoryProvider),
  );
});

final selectedZoneProvider = StateProvider<String>((ref) {
  return 'Comedor';
});
