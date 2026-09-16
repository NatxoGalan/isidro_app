import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../data/models/table_dto.dart';
import '../providers/table_provider.dart';

class MoveTableModal extends ConsumerStatefulWidget {
  final List<TableEntity> occupiedTables;
  final List<TableEntity> freeTables;
  final VoidCallback onMove;

  const MoveTableModal({
    super.key,
    required this.occupiedTables,
    required this.freeTables,
    required this.onMove,
  });

  @override
  ConsumerState<MoveTableModal> createState() => _MoveTableModalState();
}

class _MoveTableModalState extends ConsumerState<MoveTableModal> {
  TableEntity? _fromTable;
  TableEntity? _toTable;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.swap_horiz_rounded, color: AppColors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Mover Mesa', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.label)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.gray5, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.close_rounded, size: 18, color: AppColors.gray1)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Mueve una mesa ocupada a una libre.\nLa comanda se traslada automáticamente.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.secondaryLabel), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Text('1. Mesa a mover (ocupada)', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.secondaryLabel, fontSize: 13)),
              const SizedBox(height: 12),
              _buildTableGrid(widget.occupiedTables, _fromTable, (t) => setState(() => _fromTable = t)),
              const SizedBox(height: 20),
              const Icon(Icons.arrow_downward_rounded, color: AppColors.blue, size: 28),
              const SizedBox(height: 16),
              Text('2. Mesa destino (libre)', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.secondaryLabel, fontSize: 13)),
              const SizedBox(height: 12),
              _buildTableGrid(widget.freeTables, _toTable, (t) => setState(() => _toTable = t)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.secondaryLabel, side: const BorderSide(color: AppColors.separator, width: 0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text('Cancelar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _canMove() ? _confirmMove : null,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text('Mover mesa', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableGrid(List<TableEntity> tables, TableEntity? selected, ValueChanged<TableEntity> onSelect) {
    if (tables.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.gray6, borderRadius: BorderRadius.circular(14)),
        child: Center(child: Text('No hay mesas disponibles', style: GoogleFonts.inter(color: AppColors.secondaryLabel))),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.0),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        final isSelected = selected?.id == table.id;
        return _TableSelectionCard(table: table, isSelected: isSelected, onTap: () => onSelect(table));
      },
    );
  }

  bool _canMove() => _fromTable != null && _toTable != null;

  void _confirmMove() {
    if (_fromTable != null && _toTable != null) {
      ref.read(tableProvider.notifier).moveTable(fromTableId: _fromTable!.id, toTableId: _toTable!.id);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesa ${_fromTable!.tableNumber} movida a Mesa ${_toTable!.tableNumber}'), backgroundColor: AppColors.green),
      );
    }
  }
}

class _TableSelectionCard extends StatelessWidget {
  final TableEntity table;
  final bool isSelected;
  final VoidCallback onTap;

  const _TableSelectionCard({required this.table, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.blue : AppColors.separator.withValues(alpha: 0.5), width: isSelected ? 1.5 : 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(table.tableNumber, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: isSelected ? AppColors.blue : AppColors.label)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: table.isOccupied ? AppColors.green.withValues(alpha: 0.1) : AppColors.gray5,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(table.isOccupied ? 'Ocupada' : 'Libre', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: table.isOccupied ? AppColors.green : AppColors.gray1)),
            ),
          ],
        ),
      ),
    );
  }
}
