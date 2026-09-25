import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_dto.dart';
import '../../data/models/category_dto.dart';
import '../../core/utils/constants.dart';
import 'auth_provider.dart';

final productsProvider = StreamProvider<List<ProductEntity>>((ref) {
  return ref.read(productRepositoryProvider).watchProducts(Constants.defaultVenueId);
});

final allProductsProvider = StreamProvider<List<ProductEntity>>((ref) {
  return ref.read(productRepositoryProvider).watchAllProducts(Constants.defaultVenueId);
});

/// Categorías desde Firestore (ordenadas), para chips y desplegables.
final categoriesProvider = StreamProvider<List<CategoryEntity>>((ref) {
  final stream = ref
      .read(productRepositoryProvider)
      .watchCategories(Constants.defaultVenueId);
  return stream.map((cats) {
    final sorted = List<CategoryEntity>.from(cats)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted.where((c) => c.status == CategoryStatus.active).toList();
  });
});