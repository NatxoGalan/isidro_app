import '../core/utils/constants.dart';
import '../data/models/order_dto.dart';

/// Resultado de separar una comanda en comida y bebida.
class TicketGroups {
  final List<OrderItemEntity> food;
  final List<OrderItemEntity> drinks;

  const TicketGroups({required this.food, required this.drinks});
}

/// Separa los items en comida y bebida según la categoría. La comida y la
/// bebida se imprimen en tiquets distintos.
TicketGroups splitFoodAndDrinks(List<OrderItemEntity> items) {
  final food = <OrderItemEntity>[];
  final drinks = <OrderItemEntity>[];
  for (final item in items) {
    if (Constants.isDrinkItem(item.categoryId, item.categoryName)) {
      drinks.add(item);
    } else {
      food.add(item);
    }
  }
  return TicketGroups(food: food, drinks: drinks);
}
