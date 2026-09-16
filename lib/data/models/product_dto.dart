import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductAvailability { available, unavailable }

class ProductEntity {
  final String id;
  final String categoryId;
  final String venueId;
  final String name;
  final String description;
  final double basePrice;
  final String? imageUrl;
  final bool isAvailable;
  final bool isTakeaway;
  final int sortOrder;
  final List<ModifierDefinition> modifiers;
  final String? sku;

  const ProductEntity({
    required this.id,
    required this.categoryId,
    required this.venueId,
    required this.name,
    required this.description,
    required this.basePrice,
    this.imageUrl,
    this.isAvailable = true,
    this.isTakeaway = false,
    this.sortOrder = 0,
    this.modifiers = const [],
    this.sku,
  });

  factory ProductEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductEntity(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      venueId: data['venueId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      basePrice: (data['basePrice'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'],
      isAvailable: data['isAvailable'] ?? true,
      isTakeaway: data['isTakeaway'] ?? false,
      sortOrder: data['sortOrder'] ?? 0,
      modifiers: (data['modifiers'] as List?)
          ?.map((m) => ModifierDefinition.fromMap(m as Map<String, dynamic>))
          .toList() ?? [],
      sku: data['sku'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'categoryId': categoryId,
    'venueId': venueId,
    'name': name,
    'description': description,
    'basePrice': basePrice,
    'imageUrl': imageUrl,
    'isAvailable': isAvailable,
    'isTakeaway': isTakeaway,
    'sortOrder': sortOrder,
    'modifiers': modifiers.map((m) => m.toMap()).toList(),
    'sku': sku,
  };
}

class ModifierDefinition {
  final String modifierId;
  final String name;
  final double additionalPrice;
  final bool required;
  final List<ModifierOption> options;

  const ModifierDefinition({
    required this.modifierId,
    required this.name,
    this.additionalPrice = 0.0,
    this.required = false,
    this.options = const [],
  });

  factory ModifierDefinition.fromMap(Map<String, dynamic> map) {
    return ModifierDefinition(
      modifierId: map['modifierId'] ?? '',
      name: map['name'] ?? '',
      additionalPrice: (map['additionalPrice'] as num?)?.toDouble() ?? 0.0,
      required: map['required'] ?? false,
      options: (map['options'] as List?)
          ?.map((o) => ModifierOption.fromMap(o as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() => {
    'modifierId': modifierId,
    'name': name,
    'additionalPrice': additionalPrice,
    'required': required,
    'options': options.map((o) => o.toMap()).toList(),
  };
}

class ModifierOption {
  final String optionId;
  final String name;
  final double priceDelta;

  const ModifierOption({
    required this.optionId,
    required this.name,
    this.priceDelta = 0.0,
  });

  factory ModifierOption.fromMap(Map<String, dynamic> map) {
    return ModifierOption(
      optionId: map['optionId'] ?? '',
      name: map['name'] ?? '',
      priceDelta: (map['priceDelta'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
    'optionId': optionId,
    'name': name,
    'priceDelta': priceDelta,
  };
}
