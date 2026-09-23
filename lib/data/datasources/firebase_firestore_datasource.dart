import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/constants.dart';
import '../models/table_dto.dart';
import '../models/order_dto.dart';
import '../models/product_dto.dart';
import '../models/category_dto.dart';
import '../models/printer_dto.dart';

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
}