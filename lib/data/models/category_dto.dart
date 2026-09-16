import 'package:cloud_firestore/cloud_firestore.dart';

enum CategoryStatus { active, inactive }

class CategoryEntity {
  final String id;
  final String venueId;
  final String name;
  final String? imageUrl;
  final int sortOrder;
  final CategoryStatus status;
  final List<String> productIds;

  const CategoryEntity({
    required this.id,
    required this.venueId,
    required this.name,
    this.imageUrl,
    this.sortOrder = 0,
    this.status = CategoryStatus.active,
    this.productIds = const [],
  });

  factory CategoryEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryEntity(
      id: doc.id,
      venueId: data['venueId'] ?? '',
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'],
      sortOrder: data['sortOrder'] ?? 0,
      status: CategoryStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => CategoryStatus.active,
      ),
      productIds: (data['productIds'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'venueId': venueId,
    'name': name,
    'imageUrl': imageUrl,
    'sortOrder': sortOrder,
    'status': status.name,
    'productIds': productIds,
  };
}
