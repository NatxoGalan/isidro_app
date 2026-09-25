import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/constants.dart';
import '../models/table_dto.dart';
import '../models/order_dto.dart';
import '../models/product_dto.dart';
import '../models/category_dto.dart';
import '../models/printer_dto.dart';
import '../models/print_job_dto.dart';

class FirebaseFirestoreDatasource {
  final FirebaseFirestore _firestore;

  FirebaseFirestoreDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Exponer firestore para batch operations
  FirebaseFirestore get firestore => _firestore;

  Stream<List<TableEntity>> watchTables(String venueId) {
    return _firestore
        .collection(Constants.collectionTables)
        .where('venueId', isEqualTo: venueId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TableEntity.fromFirestore(doc))
            .toList());
  }

  Future<void> updateTableStatus(String tableId, String status) async {
    await _firestore.collection(Constants.collectionTables).doc(tableId).update({
      'status': status,
      'lastActivityAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTable(String tableId, Map<String, dynamic> data) async {
    await _firestore.collection(Constants.collectionTables).doc(tableId).update(data);
  }

  Stream<OrderEntity?> watchOrder(String orderId) {
    return _firestore
        .collection(Constants.collectionOrders)
        .doc(orderId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? OrderEntity.fromFirestore(snapshot) : null);
  }

  /// Todas las órdenes abiertas (borrador + enviadas) del local.
  Stream<List<OrderEntity>> watchOpenOrders(String venueId) {
    return _firestore
        .collection(Constants.collectionOrders)
        .where('venueId', isEqualTo: venueId)
        .where('status', whereIn: [Constants.orderDraft, Constants.orderPending])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderEntity.fromFirestore(doc))
            .toList());
  }

  Future<String> createOrder(OrderEntity order) async {
    final ref = await _firestore.collection(Constants.collectionOrders).add(order.toFirestore());
    return ref.id;
  }

  Future<void> updateOrder(String orderId, Map<String, dynamic> data) async {
    await _firestore.collection(Constants.collectionOrders).doc(orderId).update(data);
  }

  Future<void> deleteOrder(String orderId) async {
    await _firestore.collection(Constants.collectionOrders).doc(orderId).delete();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection(Constants.collectionOrders).doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> mergeOrders({
    required String targetOrderId,
    required String sourceOrderId,
  }) async {
    final batch = _firestore.batch();
    final ordersRef = _firestore.collection(Constants.collectionOrders);

    // Leer ambas órdenes
    final targetDoc = await ordersRef.doc(targetOrderId).get();
    final sourceDoc = await ordersRef.doc(sourceOrderId).get();

    if (!targetDoc.exists || !sourceDoc.exists) return;

    final targetOrder = OrderEntity.fromFirestore(targetDoc);
    final sourceOrder = OrderEntity.fromFirestore(sourceDoc);

    // Combinar items: sumar cantidades de mismo producto + modifiers
    final mergedItems = _mergeOrderItems(targetOrder.items, sourceOrder.items);

    // Actualizar orden destino con items fusionados
    batch.update(ordersRef.doc(targetOrderId), {
      'items': mergedItems.map((i) => i.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Eliminar orden origen
    batch.delete(ordersRef.doc(sourceOrderId));

    await batch.commit();
  }

  // Helper: fusionar items sumando cantidades de mismo producto + modifiers
  List<OrderItemEntity> _mergeOrderItems(List<OrderItemEntity> a, List<OrderItemEntity> b) {
    final map = <String, OrderItemEntity>{};
    
    for (final item in [...a, ...b]) {
      // Clave compuesta: productId + modifiers (ordenados)
      final modKey = item.modifiers.map((m) => '${m.modifierId}:${m.optionId}').toList()..sort();
      final key = '${item.productId}_${modKey.join(',')}';
      
      if (map.containsKey(key)) {
        map[key] = map[key]!.copyWith(quantity: map[key]!.quantity + item.quantity);
      } else {
        map[key] = item;
      }
    }
    
    return map.values.toList();
  }

  Stream<List<ProductEntity>> watchProducts(String venueId) {
    return _firestore
        .collection(Constants.collectionProducts)
        .where('venueId', isEqualTo: venueId)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductEntity.fromFirestore(doc))
            .toList());
  }

  Stream<List<CategoryEntity>> watchCategories(String venueId) {
    return _firestore
        .collection(Constants.collectionCategories)
        .where('venueId', isEqualTo: venueId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryEntity.fromFirestore(doc))
            .toList());
  }

  Future<void> updateProductAvailability(String productId, bool available) async {
    await _firestore.collection(Constants.collectionProducts).doc(productId).update({
      'isAvailable': available,
    });
  }

  Future<void> addTable(Map<String, dynamic> data) async {
    await _firestore.collection(Constants.collectionTables).add(data);
  }

  Stream<List<ProductEntity>> watchAllProducts(String venueId) {
    return _firestore
        .collection(Constants.collectionProducts)
        .where('venueId', isEqualTo: venueId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductEntity.fromFirestore(doc))
            .toList());
  }

  Future<void> addProduct(Map<String, dynamic> data) async {
    await _firestore.collection(Constants.collectionProducts).add(data);
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _firestore.collection(Constants.collectionProducts).doc(productId).update(data);
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection(Constants.collectionProducts).doc(productId).delete();
  }

  Future<void> deleteTable(String tableId) async {
    await _firestore.collection(Constants.collectionTables).doc(tableId).delete();
  }

  CollectionReference<Map<String, dynamic>> _printersRef(String venueId) {
    return _firestore
        .collection(Constants.collectionVenues)
        .doc(venueId)
        .collection(Constants.collectionPrinters);
  }

  Stream<List<PrinterEntity>> watchPrinters(String venueId) {
    return _printersRef(venueId).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => PrinterEntity.fromFirestore(doc)).toList());
  }

  Future<String> addPrinter(String venueId, Map<String, dynamic> data) async {
    final ref = await _printersRef(venueId).add(data);
    return ref.id;
  }

  Future<void> updatePrinter(String venueId, String printerId, Map<String, dynamic> data) async {
    await _printersRef(venueId).doc(printerId).update(data);
  }

  Future<void> deletePrinter(String venueId, String printerId) async {
    await _printersRef(venueId).doc(printerId).delete();
  }

  CollectionReference<Map<String, dynamic>> _jobsRef(String venueId) {
    return _firestore
        .collection(Constants.collectionVenues)
        .doc(venueId)
        .collection(Constants.collectionPrintJobs);
  }

  /// Trabajos pendientes de imprimir (relay para dispositivos sin WiFi).
  Stream<List<PrintJobEntity>> watchPendingJobs(String venueId) {
    return _jobsRef(venueId)
        .where('status', isEqualTo: PrintJobStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PrintJobEntity.fromFirestore(doc))
            .toList());
  }

  /// Todos los trabajos recientes (para ver la cola en Impresoras).
  Stream<List<PrintJobEntity>> watchRecentJobs(String venueId, {int limit = 30}) {
    return _jobsRef(venueId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PrintJobEntity.fromFirestore(doc))
            .toList());
  }

  Future<String> addPrintJob(String venueId, Map<String, dynamic> data) async {
    final ref = await _jobsRef(venueId).add(data);
    return ref.id;
  }

  /// Reclama un trabajo de forma atómica: solo el primero lo consigue.
  /// Devuelve true si este dispositivo se lo ha quedado.
  Future<bool> claimPrintJob(String venueId, String jobId, String deviceId) async {
    final doc = _jobsRef(venueId).doc(jobId);
    try {
      final claimed = await _firestore.runTransaction((tx) async {
        final snap = await tx.get(doc);
        if (!snap.exists) return false;
        final data = snap.data() as Map<String, dynamic>;
        if (data['status'] != PrintJobStatus.pending.name) return false;
        tx.update(doc, {
          'status': PrintJobStatus.printing.name,
          'claimedBy': deviceId,
        });
        return true;
      });
      return claimed;
    } catch (_) {
      return false;
    }
  }

  Future<void> finishPrintJob(
    String venueId,
    String jobId, {
    required bool ok,
    String? error,
  }) async {
    await _jobsRef(venueId).doc(jobId).update({
      'status': ok ? PrintJobStatus.done.name : PrintJobStatus.failed.name,
      'printedAt': FieldValue.serverTimestamp(),
      'error': error,
    });
  }

  Future<void> requeuePrintJob(String venueId, String jobId) async {
    await _jobsRef(venueId).doc(jobId).update({
      'status': PrintJobStatus.pending.name,
      'claimedBy': null,
      'error': null,
    });
  }

  Future<void> deletePrintJob(String venueId, String jobId) async {
    await _jobsRef(venueId).doc(jobId).delete();
  }

  /// Borra trabajos terminados (done/failed) más antiguos de [olderThan].
  Future<void> deleteOldJobs(String venueId, DateTime olderThan) async {
    final snap = await _jobsRef(venueId)
        .where('status', whereIn: [
          PrintJobStatus.done.name,
          PrintJobStatus.failed.name,
        ])
        .get();
    final batch = _firestore.batch();
    var count = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      final ts = data['printedAt'] as Timestamp? ??
          data['createdAt'] as Timestamp?;
      if (ts != null && ts.toDate().isBefore(olderThan)) {
        batch.delete(doc.reference);
        count++;
      }
      if (count >= 400) break;
    }
    if (count > 0) await batch.commit();
  }
}