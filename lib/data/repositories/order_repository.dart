import '../../core/utils/constants.dart';
import '../models/order_dto.dart';
import '../datasources/firebase_firestore_datasource.dart';

class OrderRepository {
  final FirebaseFirestoreDatasource _datasource;

  OrderRepository({FirebaseFirestoreDatasource? datasource})
      : _datasource = datasource ?? FirebaseFirestoreDatasource();

  Stream<OrderEntity?> watchOrder(String orderId) {
    return _datasource.watchOrder(orderId);
  }

  Future<String> createOrder(OrderEntity order) async {
    return await _datasource.createOrder(order);
  }

  Future<void> updateOrder(String orderId, Map<String, dynamic> data) async {
    await _datasource.updateOrder(orderId, data);
  }

  Future<void> deleteOrder(String orderId) async {
    await _datasource.deleteOrder(orderId);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _datasource.updateOrderStatus(orderId, status);
  }

  Future<void> sendToKitchen(String orderId) async {
    await _datasource.updateOrderStatus(orderId, Constants.orderPending);
  }

  Future<void> mergeOrders({
    required String targetOrderId,
    required String sourceOrderId,
  }) async {
    await _datasource.mergeOrders(
      targetOrderId: targetOrderId,
      sourceOrderId: sourceOrderId,
    );
  }
}