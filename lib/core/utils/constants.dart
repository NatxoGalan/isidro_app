class Constants {
  static const String appName = 'LaSede';
  static const String appVersion = '1.1.4';
  static const String collectionVenues = 'venues';
  static const String collectionZones = 'zones';
  static const String collectionTables = 'tables';
  static const String collectionCategories = 'categories';
  static const String collectionProducts = 'products';
  static const String collectionOrders = 'orders';
  static const String collectionPayments = 'payments';
  static const String collectionUsers = 'users';
  static const String collectionPrinters = 'printers';
  static const String collectionPrintJobs = 'printJobs';
  static const String defaultVenueId = 'isidro-bar';
  static const String defaultVenueName = 'LaSede';
  static const String currencySymbol = '€';
  static const String statusFree = 'free';
  static const String statusOccupied = 'occupied';
  static const String statusReserved = 'reserved';
  static const String statusCleaning = 'cleaning';
  static const String orderDraft = 'draft';
  static const String orderPending = 'pending';
  static const String orderReady = 'ready';
  static const String orderServed = 'served';
  static const String orderPaid = 'paid';
  static const String orderCancelled = 'cancelled';
  static const String printerBar = 'bar';
  static const String printerKitchen = 'kitchen';
  /// Cuenta de pruebas: con ella todo se simula (no imprime nada).
  static const String testAccountEmail = 'natxotest@gmail.com';

  static bool isTestAccount(String email) {
    return email.trim().toLowerCase() == testAccountEmail;
  }
  /// Categorías que salen en ticket separado de bebidas (pero a Cocina).
  static const List<String> drinksCategoryIds = ['bebidas', 'varios', 'cafeteria'];
  /// Categorías que comparten la lista global de ingredientes extra.
  static const List<String> ingredientsCategoryIds = [
    'bocadillos',
    'medios-bocadillos',
  ];

  /// Normaliza un nombre de categoría (minúsculas y sin tildes).
  static String _normalizeCategory(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .trim();

  /// true si la categoría es de bocadillos (incluye "Medios Bocadillos").
  /// Se compara por nombre además del id, porque los ids pueden generarse
  /// automáticamente desde Firestore.
  static bool isBocadilloCategoryName(String name) =>
      _normalizeCategory(name).contains('bocadillo');

  /// true si la categoría es de bebidas/varios/cafetería.
  static bool isDrinksCategoryName(String name) {
    final n = _normalizeCategory(name);
    return n == 'bebidas' ||
        n == 'varios' ||
        n.contains('cafeter') ||
        n.contains('bebida');
  }

  /// ¿El producto usa la lista global de ingredientes extra?
  static bool usesSharedIngredients(String categoryId, String categoryName) =>
      ingredientsCategoryIds.contains(categoryId) ||
      isBocadilloCategoryName(categoryName);

  /// ¿El item es de bebida (para el ticket separado)?
  static bool isDrinkItem(String categoryId, String categoryName) =>
      drinksCategoryIds.contains(categoryId) ||
      isDrinksCategoryName(categoryName);
  static const String methodCard = 'card';
  static const String methodCash = 'cash';
  static const String methodCashNoChange = 'cash_no_change';
  static const String methodOther = 'other';
  static const String methodInvitation = 'invitation';
}

class Validators {
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }

  static String? positiveNumber(String? value, String fieldName) {
    if (value == null || double.tryParse(value) == null || double.parse(value) <= 0) {
      return '$fieldName debe ser un número positivo';
    }
    return null;
  }
}