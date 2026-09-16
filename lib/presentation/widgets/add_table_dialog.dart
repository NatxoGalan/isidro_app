import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../core/utils/constants.dart';
import '../providers/table_provider.dart';

class AddTableDialog extends ConsumerStatefulWidget {
  final String initialZone;
  const AddTableDialog({super.key, required this.initialZone});

  @override
  ConsumerState<AddTableDialog> createState() => _AddTableDialogState();
}

class _AddTableDialogState extends ConsumerState<AddTableDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _tableNumber;
  late int _capacity;
  late String _zone;

  @override
  void initState() {
    super.initState();
    _zone = widget.initialZone;
    _capacity = 4;
    _tableNumber = '';
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tableProvider);
    final existingTables = tablesAsync.value ?? [];
    final zoneTables = existingTables.where((t) => t.zoneId == _zone).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Nueva mesa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _zone,
                        items: const [
                          DropdownMenuItem(value: 'Comedor', child: Text('Comedor')),
                          DropdownMenuItem(value: 'Terraza', child: Text('Terraza')),
                        ],
                        onChanged: (v) => setState(() => _zone = v!),
                        decoration: const InputDecoration(labelText: 'Zona'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Número de mesa *',
                          hintText: 'Ej: 7, T5, B1...',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          final exists = zoneTables.any((t) => t.tableNumber == v.trim());
                          if (exists) return 'Ya existe una mesa con ese número';
                          return null;
                        },
                        onChanged: (v) => _tableNumber = v.trim(),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _capacity,
                        items: List.generate(11, (i) => i + 2)
                            .map((c) => DropdownMenuItem(value: c, child: Text('$c personas')))
                            .toList(),
                        onChanged: (v) => setState(() => _capacity = v!),
                        decoration: const InputDecoration(labelText: 'Capacidad'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Crear'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(tableProvider.notifier).addTable(
      venueId: Constants.defaultVenueId,
      zoneId: _zone,
      tableNumber: _tableNumber,
      capacity: _capacity,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(ref.context).showSnackBar(
      SnackBar(
        content: Text('Mesa $_tableNumber creada en $_zone'),
        backgroundColor: AppTheme.success,
      ),
    );
  }
}
