import 'package:flutter/material.dart';
import '../../data/models/product_dto.dart';
import '../../core/utils/formatters.dart';
import '../../config/theme.dart';

class ProductManagementTile extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductManagementTile({super.key, required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getIconForCategory(product.categoryId), color: AppTheme.primary, size: 24),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(product.description.isNotEmpty ? product.description : 'Sin descripción',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(Formatters.currency(product.basePrice), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16)),
            IconButton(icon: const Icon(Icons.edit, color: AppTheme.textSecondary), onPressed: onEdit, tooltip: 'Editar'),
            IconButton(icon: const Icon(Icons.delete, color: AppTheme.error), onPressed: onDelete, tooltip: 'Eliminar'),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'bocadillos': return Icons.lunch_dining;
      case 'bebidas': return Icons.local_drink;
      case 'cafetería': return Icons.coffee;
      case 'tapas': return Icons.fastfood;
      default: return Icons.restaurant;
    }
  }
}