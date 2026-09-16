import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/constants.dart';
import '../models/table_dto.dart';
import '../datasources/firebase_firestore_datasource.dart';

class TableRepository {
  final FirebaseFirestoreDatasource _datasource;

  TableRepository({FirebaseFirestoreDatasource? datasource})
      : _datasource = datasource ?? FirebaseFirestoreDatasource();

  Stream<List<TableEntity>> watchTables(String venueId) {
    return _datasource.watchTables(venueId);
  }

  Future<void> updateTableStatus(String tableId, String status) async {
    await _datasource.updateTableStatus(tableId, status);
  }

  Future<void> updateTable(String tableId, Map<String, dynamic> data) async {
    await _datasource.updateTable(tableId, data);
  }

  Future<void> openTable(String tableId, DateTime openedAt) async {
    await _datasource.updateTable(tableId, {
      'status': Constants.statusOccupied,
      'openedAt': openedAt,
      'lastActivityAt': openedAt,
    });
  }

  Future<void> closeTable(String tableId) async {
    await _datasource.updateTable(tableId, {
      'status': Constants.statusFree,
      'openedAt': null,
      'currentOrderId': null,
      'lastActivityAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> assignOrder(String tableId, String orderId) async {
    await _datasource.updateTable(tableId, {'currentOrderId': orderId});
  }

  Future<void> moveTable({
    required String fromTableId,
    required String toTableId,
    required String orderId,
  }) async {
    final batch = _datasource.firestore.batch();
    final tablesRef = _datasource.firestore.collection(Constants.collectionTables);

    // Mesa origen → libre
    batch.update(tablesRef.doc(fromTableId), {
      'status': Constants.statusFree,
      'currentOrderId': null,
      'openedAt': null,
      'hasItems': false,
      'lastActivityAt': FieldValue.serverTimestamp(),
    });

    // Mesa destino → ocupada con la orden
    batch.update(tablesRef.doc(toTableId), {
      'status': Constants.statusOccupied,
      'currentOrderId': orderId,
      'hasItems': true,
      'openedAt': FieldValue.serverTimestamp(),
      'lastActivityAt': FieldValue.serverTimestamp(),
    });

    // Actualizar orden con nueva mesa
    batch.update(_datasource.firestore.collection(Constants.collectionOrders).doc(orderId), {
      'tableId': toTableId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> addTable({
    required String venueId,
    required String zoneId,
    required String tableNumber,
    required int capacity,
  }) async {
    await _datasource.addTable({
      'venueId': venueId,
      'zoneId': zoneId,
      'tableNumber': tableNumber,
      'capacity': capacity,
      'status': Constants.statusFree,
      'currentOrderId': null,
      'openedAt': null,
      'lastActivityAt': null,
    });
  }

  Future<void> deleteTable(String tableId) async {
    await _datasource.deleteTable(tableId);
  }

  Future<void> mergeTables({
    required String targetTableId,
    required String sourceTableId,
    required String targetOrderId,
    required String sourceOrderId,
  }) async {
    final batch = _datasource.firestore.batch();
    final tablesRef = _datasource.firestore.collection(Constants.collectionTables);
    final ordersRef = _datasource.firestore.collection(Constants.collectionOrders);

    // Liberar mesa origen
    batch.update(tablesRef.doc(sourceTableId), {
      'status': Constants.statusFree,
      'currentOrderId': null,
      'hasItems': false,
      'openedAt': null,
      'lastActivityAt': FieldValue.serverTimestamp(),
    });

    // Mesa destino mantiene su orden (fusionado)
    batch.update(tablesRef.doc(targetTableId), {
      'currentOrderId': targetOrderId,
      'hasItems': true,
      'lastActivityAt': FieldValue.serverTimestamp(),
    });

    // Eliminar orden origen
    batch.delete(_datasource.firestore.collection(Constants.collectionOrders).doc(sourceOrderId));

    // Actualizar orden destino con items fusionados (se hace en order_repository)
    batch.update(ordersRef.doc(targetOrderId), {
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}