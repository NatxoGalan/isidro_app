import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../presentation/widgets/merge_tables_modal.dart';
import '../../presentation/widgets/move_table_modal.dart';
import '../../presentation/providers/table_provider.dart';
import '../../data/models/table_dto.dart';

class TableToolbar extends ConsumerWidget {
  const TableToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tableProvider);
    final allTables = tablesAsync.value ?? [];
    final occupiedTables = allTables.where((t) => t.isOccupied).toList();
    final freeTables =
        allTables.where((t) => t.status == TableStatus.free).toList();

    final canMerge = occupiedTables.length >= 2;
    final canMove = occupiedTables.isNotEmpty && freeTables.isNotEmpty;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.separator.withValues(alpha: 0.3),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ToolbarButton(
                icon: Icons.merge_type_rounded,
                label: 'Juntar',
                enabled: canMerge,
                onTap: canMerge ? () => _showMergeModal(context, ref) : null,
              ),
              Container(
                width: 0.5,
                height: 24,
                color: AppColors.separator,
              ),
              _ToolbarButton(
                icon: Icons.swap_horiz_rounded,
                label: 'Mover',
                enabled: canMove,
                onTap: canMove ? () => _showMoveModal(context, ref, allTables) : null,
              ),
              Container(
                width: 0.5,
                height: 24,
                color: AppColors.separator,
              ),
              _ToolbarButton(
                icon: Icons.delete_outline_rounded,
                label: 'Eliminar',
                enabled: true,
                isDestructive: true,
                onTap: () => _showDeleteTableDialog(context, ref, allTables),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMergeModal(BuildContext context, WidgetRef ref) {
    final occupiedTables = ref
            .read(tableProvider)
            .value
            ?.where((t) => t.isOccupied)
            .toList() ??
        [];
    if (occupiedTables.length < 2) return;

    showDialog(
      context: context,
      builder: (_) => MergeTablesModal(occupiedTables: occupiedTables),
    );
  }

  void _showMoveModal(
      BuildContext context, WidgetRef ref, List<TableEntity> allTables) {
    final occupiedTables = allTables.where((t) => t.isOccupied).toList();
    final freeTables =
        allTables.where((t) => t.status == TableStatus.free).toList();

    if (occupiedTables.isEmpty || freeTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay mesas ocupadas o libres disponibles')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => MoveTableModal(
        occupiedTables: occupiedTables,
        freeTables: freeTables,
        onMove: () {},
      ),
    );
  }

  void _showDeleteTableDialog(
      BuildContext context, WidgetRef ref, List<TableEntity> allTables) {
    final freeTables =
        allTables.where((t) => t.status == TableStatus.free).toList();

    if (freeTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay mesas libres para eliminar')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar mesa'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: freeTables.length,
            itemBuilder: (_, index) {
              final table = freeTables[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.red, size: 20),
                ),
                title: Text('Mesa ${table.tableNumber}',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text('${table.capacity} personas',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.secondaryLabel)),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.gray3, size: 20),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDeleteTable(context, ref, table);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: TextStyle(color: AppColors.blue)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTable(
      BuildContext context, WidgetRef ref, TableEntity table) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar Mesa ${table.tableNumber}?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: TextStyle(color: AppColors.blue)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(tableProvider.notifier).deleteTable(table.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Mesa ${table.tableNumber} eliminada'),
                    backgroundColor: AppColors.green,
                  ),
                );
              }
            },
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.enabled = true,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? AppColors.gray4
        : isDestructive
            ? AppColors.red
            : AppColors.blue;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
