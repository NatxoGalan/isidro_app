class Constants {
  static const String appName = 'LaSede';
  static const String appVersion = '1.0.0';
  static const String collectionVenues = 'venues';
  static const String collectionZones = 'zones';
  static const String collectionTables = 'tables';
  static const String collectionCategories = 'categories';
  static const String collectionProducts = 'products';
  static const String collectionOrders = 'orders';
  static const String collectionPayments = 'payments';
  static const String collectionUsers = 'users';
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