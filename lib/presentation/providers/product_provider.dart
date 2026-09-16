import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_dto.dart';
import '../../core/utils/constants.dart';
import 'auth_provider.dart';

final productsProvider = StreamProvider<List<ProductEntity>>((ref) {
  return ref.read(productRepositoryProvider).watchProducts(Constants.defaultVenueId);
});

final allProductsProvider = StreamProvider<List<ProductEntity>>((ref) {
  return ref.read(productRepositoryProvider).watchAllProducts(Constants.defaultVenueId);
});