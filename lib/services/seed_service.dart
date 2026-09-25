import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/constants.dart';

class SeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Map<String, String> categorySlugs = {
    'Tapas': 'tapas',
    'Bocadillos': 'bocadillos',
    'Medios Bocadillos': 'medios-bocadillos',
    'Bebidas': 'bebidas',
    'Varios': 'varios',
    'Cafetería': 'cafeteria',
  };

  Future<void> seedIfEmpty() async {
    final tablesExist = await _collectionHasData(Constants.collectionTables);
    final categoriesExist = await _collectionHasData(Constants.collectionCategories);
    final productsExist = await _collectionHasData(Constants.collectionProducts);

    if (!tablesExist) await _seedTables();
    if (!categoriesExist) await _seedCategories();
    if (!productsExist) await _seedProducts();
    // Migración: categorías/productos nuevos sin borrar lo existente
    await _ensureMediosBocadillos();
  }

  /// Crea la categoría Medios Bocadillos + ejemplos si no existen.
  Future<void> _ensureMediosBocadillos() async {
    try {
      final catDoc = await _firestore
          .collection(Constants.collectionCategories)
          .doc('medios-bocadillos')
          .get();
      if (!catDoc.exists) {
        await _firestore
            .collection(Constants.collectionCategories)
            .doc('medios-bocadillos')
            .set({
          'name': 'Medios Bocadillos',
          'venueId': Constants.defaultVenueId,
          'sortOrder': 2,
          'imageUrl': null,
          'status': 'active',
        });
      }
      final existing = await _firestore
          .collection(Constants.collectionProducts)
          .where('venueId', isEqualTo: Constants.defaultVenueId)
          .where('categoryId', isEqualTo: 'medios-bocadillos')
          .limit(1)
          .get();
      if (existing.docs.isEmpty) {
        final batch = _firestore.batch();
        final medios = [
          {'name': 'Medio de Jamón', 'basePrice': 4.5, 'sortOrder': 0, 'description': 'Medio bocadillo de jamón serrano'},
          {'name': 'Medio Mixto', 'basePrice': 4.2, 'sortOrder': 1, 'description': 'Medio bocadillo de jamón y queso'},
          {'name': 'Medio de Tortilla', 'basePrice': 4.0, 'sortOrder': 2, 'description': 'Medio bocadillo de tortilla de patata'},
          {'name': 'Medio de Atún', 'basePrice': 4.0, 'sortOrder': 3, 'description': 'Medio bocadillo de atún con tomate'},
          {'name': 'Medio de Queso', 'basePrice': 3.8, 'sortOrder': 4, 'description': 'Medio bocadillo de queso manchego'},
        ];
        for (final m in medios) {
          final doc = _firestore.collection(Constants.collectionProducts).doc();
          batch.set(doc, {
            'name': m['name'],
            'basePrice': m['basePrice'],
            'categoryId': 'medios-bocadillos',
            'venueId': Constants.defaultVenueId,
            'isAvailable': true,
            'sortOrder': m['sortOrder'],
            'description': m['description'],
            'modifiers': [],
          });
        }
        await batch.commit();
      }
    } catch (_) {}
  }

  Future<bool> _collectionHasData(String collection) async {
    final snap = await _firestore.collection(collection).limit(1).get();
    return snap.docs.isNotEmpty;
  }

  Future<void> _seedTables() async {
    final batch = _firestore.batch();
    final tables = [
      {'tableNumber': '1', 'capacity': 2, 'status': 'free', 'venueId': Constants.defaultVenueId, 'zoneId': 'Comedor', 'currentOrderId': null, 'openedAt': null, 'lastActivityAt': null},
      {'tableNumber': '2', 'capacity': 2, 'status': 'free', 'venueId': Constants.defaultVenueId, 'zoneId': 'Comedor', 'currentOrderId': null, 'openedAt': null, 'lastActivityAt': null},
      {'tableNumber': '3', 'capacity': 4, 'status': 'free', 'venueId': Constants.defaultVenueId, 'zoneId': 'Comedor', 'currentOrderId': null, 'openedAt': null, 'lastActivityAt': null},
      {'tableNumber': '4', 'capacity': 4, 'status': 'free', 'venueId': Constants.defaultVenueId, 'zoneId': 'Comedor', 'currentOrderId': null, 'openedAt': null, 'lastActivityAt': null},
      {'tableNumber': '5', 'capacity': 6, 'status': 'free', 'venueId': Constants.defaultVenueId, 'zoneId': 'Comedor', 'currentOrderId': null, 'openedAt': null, 'lastActivityAt': null},
      {'tableNumber': '6', 'capacity': 4, 'status': 'free', 'venueId': Constants.defaultVenueId, 'zoneId': 'Comedor', 'currentOrderId': null, 'openedAt': null, 'lastActivityAt': null},
      {'tableNumber': 'T1', 'capacity': 4, 'status': 'free', 'venueId': Constants.defaultVenueId, 'zoneId': 'Terraza', 'currentOrderId': null, 'openedAt': null, 'lastActivityAt': null},
      {'tableNumber': 'T2', 'capacity': 4, 'status': 'free', 'venueId': Constants.defaultVenueId, 'zoneId': 'Terraza', 'currentOrderId': null, 'openedAt': null, 'lastActivityAt': null},
      {'tableNumber': 'T3', 'capacity': 2, 'status': 'free', 'venueId': Constants.defaultVenueId, 'zoneId': 'Terraza', 'currentOrderId': null, 'openedAt': null, 'lastActivityAt': null},
      {'tableNumber': 'T4', 'capacity': 6, 'status': 'free', 'venueId': Constants.defaultVenueId, 'zoneId': 'Terraza', 'currentOrderId': null, 'openedAt': null, 'lastActivityAt': null},
    ];

    for (final table in tables) {
      final doc = _firestore.collection(Constants.collectionTables).doc();
      batch.set(doc, table);
    }
    await batch.commit();
  }

  Future<void> _seedCategories() async {
    final batch = _firestore.batch();
    final categories = [
      {'id': 'tapas', 'name': 'Tapas', 'venueId': Constants.defaultVenueId, 'sortOrder': 0, 'imageUrl': null, 'status': 'active'},
      {'id': 'bocadillos', 'name': 'Bocadillos', 'venueId': Constants.defaultVenueId, 'sortOrder': 1, 'imageUrl': null, 'status': 'active'},
      {'id': 'medios-bocadillos', 'name': 'Medios Bocadillos', 'venueId': Constants.defaultVenueId, 'sortOrder': 2, 'imageUrl': null, 'status': 'active'},
      {'id': 'bebidas', 'name': 'Bebidas', 'venueId': Constants.defaultVenueId, 'sortOrder': 3, 'imageUrl': null, 'status': 'active'},
      {'id': 'varios', 'name': 'Varios', 'venueId': Constants.defaultVenueId, 'sortOrder': 4, 'imageUrl': null, 'status': 'active'},
      {'id': 'cafeteria', 'name': 'Cafetería', 'venueId': Constants.defaultVenueId, 'sortOrder': 5, 'imageUrl': null, 'status': 'active'},
    ];

    for (final cat in categories) {
      final doc = _firestore.collection(Constants.collectionCategories).doc(cat['id'] as String);
      batch.set(doc, cat);
    }
    await batch.commit();
  }

  Future<void> _seedProducts() async {
    final batch = _firestore.batch();

    final products = [
      {'name': 'Boquerones en vinagre', 'basePrice': 8.0, 'categoryId': 'tapas', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 0, 'description': 'Boquerones frescos en vinagre con ajo', 'modifiers': []},
      {'name': 'Pan con Tomate', 'basePrice': 4.5, 'categoryId': 'tapas', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 1, 'description': 'Pan tostado con tomate rallado y aceite de oliva', 'modifiers': []},
      {'name': 'Rabas de Sepia', 'basePrice': 8.5, 'categoryId': 'tapas', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 2, 'description': 'Aros de sepia rebozados', 'modifiers': []},
      {'name': 'Queso de Cabra', 'basePrice': 9.5, 'categoryId': 'tapas', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 3, 'description': 'Queso de cabra con miel', 'modifiers': []},
      {'name': 'Queso Frito', 'basePrice': 9.0, 'categoryId': 'tapas', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 4, 'description': 'Queso frito con salsa', 'modifiers': []},
      {'name': 'Puntilla', 'basePrice': 9.0, 'categoryId': 'tapas', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 5, 'description': 'Puntilla frita', 'modifiers': []},
      {'name': 'Oreja', 'basePrice': 8.5, 'categoryId': 'tapas', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 6, 'description': 'Oreja de cerdo frita', 'modifiers': []},
      {'name': 'Nuggets de pollo', 'basePrice': 7.0, 'categoryId': 'tapas', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 7, 'description': 'Nuggets de pollo con salsa', 'modifiers': []},
      {'name': 'Huevos Rotos', 'basePrice': 8.0, 'categoryId': 'tapas', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 8, 'description': 'Huevos fritos sobre patatas con jamón', 'modifiers': []},
      {'name': 'Bocadillo de Jamón', 'basePrice': 7.0, 'categoryId': 'bocadillos', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 0, 'description': 'Bocadillo de jamón serrano', 'modifiers': []},
      {'name': 'Bocadillo de Queso', 'basePrice': 6.5, 'categoryId': 'bocadillos', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 1, 'description': 'Bocadillo de queso manchego', 'modifiers': []},
      {'name': 'Bocadillo Mixto', 'basePrice': 7.5, 'categoryId': 'bocadillos', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 2, 'description': 'Jamón y queso', 'modifiers': []},
      {'name': 'Bocadillo de Tortilla', 'basePrice': 7.0, 'categoryId': 'bocadillos', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 3, 'description': 'Bocadillo de tortilla de patata', 'modifiers': []},
      {'name': 'Bocadillo de Atún', 'basePrice': 7.0, 'categoryId': 'bocadillos', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 4, 'description': 'Bocadillo de atún con tomate', 'modifiers': []},
      {'name': 'Cerveza', 'basePrice': 2.5, 'categoryId': 'bebidas', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 0, 'description': 'Caña de cerveza', 'modifiers': []},
      {'name': 'Cerveza grande', 'basePrice': 4.0, 'categoryId': 'bebidas', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 1, 'description': 'Tubo de cerveza', 'modifiers': []},
      {'name': 'Vino tinto', 'basePrice': 3.0, 'categoryId': 'bebidas', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 2, 'description': 'Copa de vino tinto', 'modifiers': []},
      {'name': 'Vino blanco', 'basePrice': 3.0, 'categoryId': 'bebidas', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 3, 'description': 'Copa de vino blanco', 'modifiers': []},
      {'name': 'Refresco', 'basePrice': 2.5, 'categoryId': 'bebidas', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 4, 'description': 'Refresco variedad', 'modifiers': []},
      {'name': 'Agua', 'basePrice': 1.5, 'categoryId': 'bebidas', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 5, 'description': 'Botella de agua', 'modifiers': []},
      {'name': 'Zumo natural', 'basePrice': 3.5, 'categoryId': 'bebidas', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 6, 'description': 'Zumo de naranja natural', 'modifiers': []},
      {'name': 'Papas fritas', 'basePrice': 5.0, 'categoryId': 'varios', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 0, 'description': 'Ración de patatas fritas', 'modifiers': []},
      {'name': 'Olivas', 'basePrice': 3.0, 'categoryId': 'varios', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 1, 'description': 'Plato de aceitunas', 'modifiers': []},
      {'name': 'Pan', 'basePrice': 1.0, 'categoryId': 'varios', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 2, 'description': 'Cesta de pan', 'modifiers': []},
      {'name': 'Café solo', 'basePrice': 1.5, 'categoryId': 'cafeteria', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 0, 'description': 'Café espresso', 'modifiers': []},
      {'name': 'Café con leche', 'basePrice': 2.0, 'categoryId': 'cafeteria', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 1, 'description': 'Café con leche caliente', 'modifiers': []},
      {'name': 'Cortado', 'basePrice': 1.8, 'categoryId': 'cafeteria', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 2, 'description': 'Café cortado con leche', 'modifiers': []},
      {'name': 'Chocolate caliente', 'basePrice': 3.0, 'categoryId': 'cafeteria', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 3, 'description': 'Chocolate caliente con churros', 'modifiers': []},
      {'name': 'Té', 'basePrice': 2.0, 'categoryId': 'cafeteria', 'venueId': Constants.defaultVenueId, 'isAvailable': true, 'sortOrder': 4, 'description': 'Té variado', 'modifiers': []},
    ];

    for (final product in products) {
      final doc = _firestore.collection(Constants.collectionProducts).doc();
      batch.set(doc, product);
    }
    await batch.commit();
  }

  Future<bool> hasData() async {
    final tables = await _firestore.collection(Constants.collectionTables).limit(1).get();
    return tables.docs.isNotEmpty;
  }
}
