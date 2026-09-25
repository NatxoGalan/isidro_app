import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../data/models/order_dto.dart';
import '../../../data/models/table_dto.dart';
import '../providers/table_provider.dart';

class TableCard extends ConsumerWidget {
  final TableEntity table;
  final OrderEntity? order;
  final VoidCallback onTap;

  const TableCard({super.key, required this.table, this.order, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasItems = table.hasItems;
    final o = order;
    final allSent = hasItems &&
        o != null &&
        o.items.isNotEmpty &&
        o.items.every((i) => i.unsentQuantity == 0);

    return GestureDetector(
      onTap: onTap,
      onLongPress: hasItems ? null : () => _confirmDelete(context, ref),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: hasItems ? AppColors.blue.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasItems
                ? AppColors.blue.withValues(alpha: 0.3)
                : AppColors.separator.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Table number
            Text(
              table.tableNumber,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 28,
                color: hasItems ? AppColors.blue : AppColors.label,
              ),
            ),
            const SizedBox(height: 2),
            // Capacity
            Text(
              '${table.capacity} persona${table.capacity != 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.gray1,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            // Status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: hasItems
                    ? AppColors.blue.withValues(alpha: 0.1)
                    : AppColors.gray5,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: hasItems ? AppColors.blue : AppColors.gray3,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasItems ? 'Activa' : 'Libre',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: hasItems ? AppColors.blue : AppColors.gray1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
          if (allSent)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 15),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar Mesa ${table.tableNumber}'),
        content: Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: AppColors.blue)),
          ),
          TextButton(
            onPressed: () {
              ref.read(tableProvider.notifier).deleteTable(table.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Mesa ${table.tableNumber} eliminada'),
                  backgroundColor: AppColors.red,
                ),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}
