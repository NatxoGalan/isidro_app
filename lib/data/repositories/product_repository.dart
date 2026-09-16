import '../models/product_dto.dart';
import '../models/category_dto.dart';
import '../datasources/firebase_firestore_datasource.dart';

class ProductRepository {
  final FirebaseFirestoreDatasource _datasource;

  ProductRepository({FirebaseFirestoreDatasource? datasource})
      : _datasource = datasource ?? FirebaseFirestoreDatasource();

  Stream<List<ProductEntity>> watchProducts(String venueId) {
    return _datasource.watchProducts(venueId);
  }

  Stream<List<ProductEntity>> watchAllProducts(String venueId) {
    return _datasource.watchAllProducts(venueId);
  }

  Stream<List<CategoryEntity>> watchCategories(String venueId) {
    return _datasource.watchCategories(venueId);
  }

  Future<void> updateProductAvailability(String productId, bool available) async {
    await _datasource.updateProductAvailability(productId, available);
  }

  Future<void> createProduct(ProductEntity product) async {
    await _datasource.addProduct(product.toFirestore());
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _datasource.updateProduct(productId, data);
  }

  Future<void> deleteProduct(String productId) async {
    await _datasource.deleteProduct(productId);
  }
}
