import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/repositories/table_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/printer_repository.dart';
import '../../data/models/user_dto.dart';
import 'auth_notifier.dart';

final firebaseAuthProvider = Provider<FirebaseAuthDatasource>((ref) {
  return FirebaseAuthDatasource();
});

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  return TableRepository();
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final printerRepositoryProvider = Provider<PrinterRepository>((ref) {
  return PrinterRepository();
});

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>((ref) {
  return AuthNotifier(ref.read(firebaseAuthProvider));
});