/// Ingrediente extra compartido por las categorías de bocadillos.
/// Se guarda una sola vez por local (no dentro de cada producto).
class IngredientEntity {
  final String id;
  final String name;
  final double price;

  const IngredientEntity({
    required this.id,
    required this.name,
    this.price = 0.0,
  });

  factory IngredientEntity.fromMap(Map<String, dynamic> map) {
    return IngredientEntity(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price': price,
      };

  IngredientEntity copyWith({String? id, String? name, double? price}) {
    return IngredientEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }
}
