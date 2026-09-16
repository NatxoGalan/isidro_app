import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../data/models/table_dto.dart';
import '../providers/table_provider.dart';

class MergeTablesModal extends ConsumerStatefulWidget {
  final List<TableEntity> occupiedTables;

  const MergeTablesModal({super.key, required this.occupiedTables});

  @override
  ConsumerState<MergeTablesModal> createState() => _MergeTablesModalState();
}

class _MergeTablesModalState extends ConsumerState<MergeTablesModal> {
  TableEntity? _targetTable;
  TableEntity? _sourceTable;
  int _step = 1;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(maxWidth: 400, maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Step indicators
              Row(
                children: [
                  _StepIndicator(number: 1, label: 'Destino', isActive: _step == 1, isCompleted: _step > 1),
                  Expanded(child: _StepConnector(isCompleted: _step > 1)),
                  _StepIndicator(number: 2, label: 'Origen', isActive: _step == 2, isCompleted: false),
                ],
              ),
              const SizedBox(height: 24),
              if (_step == 1) _buildStep1() else _buildStep2(),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (_step == 2)
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step = 1),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.secondaryLabel, side: const BorderSide(color: AppColors.separator, width: 0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: Text('Volver', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  if (_step == 2) const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _canProceed() ? _proceed : null,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text(_step == 1 ? 'Siguiente' : 'Juntar mesas', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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

  Widget _buildStep1() {
    final availableTables = widget.occupiedTables.where((t) => t != _sourceTable).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selecciona la mesa destino', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.label)),
        const SizedBox(height: 4),
        Text('Esta mesa recibirá los pedidos de la otra', style: GoogleFonts.inter(fontSize: 13, color: AppColors.secondaryLabel)),
        const SizedBox(height: 16),
        _buildTableGrid(availableTables, _targetTable, (t) => setState(() => _targetTable = t)),
      ],
    );
  }

  Widget _buildStep2() {
    if (_targetTable == null) return const SizedBox();
    final availableTables = widget.occupiedTables.where((t) => t.id != _targetTable!.id).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('Destino: Mesa ${_targetTable!.tableNumber}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue)),
        ),
        const SizedBox(height: 16),
        Text('Selecciona la mesa origen', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.label)),
        const SizedBox(height: 4),
        Text('Sus pedidos se sumarán a la mesa destino', style: GoogleFonts.inter(fontSize: 13, color: AppColors.secondaryLabel)),
        const SizedBox(height: 16),
        _buildTableGrid(availableTables, _sourceTable, (t) => setState(() => _sourceTable = t)),
      ],
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

  bool _canProceed() {
    if (_step == 1) return _targetTable != null;
    return _sourceTable != null && _sourceTable?.id != _targetTable?.id;
  }

  void _proceed() {
    if (_step == 1) {
      setState(() => _step = 2);
    } else {
      if (_targetTable != null && _sourceTable != null) {
        ref.read(tableProvider.notifier).mergeTables(targetTableId: _targetTable!.id, sourceTableId: _sourceTable!.id);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesa ${_sourceTable!.tableNumber} unida a Mesa ${_targetTable!.tableNumber}'), backgroundColor: AppColors.green),
        );
      }
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
                color: AppColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Ocupada', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.green)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _StepIndicator({required this.number, required this.label, required this.isActive, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? AppColors.green : (isActive ? AppColors.blue : Colors.white),
            border: Border.all(color: isCompleted ? AppColors.green : (isActive ? AppColors.blue : AppColors.separator), width: 1.5),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                : Text('$number', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: isCompleted ? Colors.white : (isActive ? AppColors.blue : AppColors.gray1))),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: isActive || isCompleted ? FontWeight.w600 : FontWeight.normal, color: isCompleted ? AppColors.green : (isActive ? AppColors.blue : AppColors.secondaryLabel)), textAlign: TextAlign.center),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  final bool isCompleted;
  const _StepConnector({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: isCompleted ? AppColors.green : AppColors.separator, borderRadius: BorderRadius.circular(1)));
  }
}
