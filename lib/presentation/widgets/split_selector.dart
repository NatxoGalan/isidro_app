import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplitSelector extends ConsumerStatefulWidget {
  const SplitSelector({super.key});

  @override
  ConsumerState<SplitSelector> createState() => _SplitSelectorState();
}

class _SplitSelectorState extends ConsumerState<SplitSelector> {
  String _mode = 'ungrouped';

  @override
  Widget build(BuildContext context) {
    final modes = [
      {'id': 'ungrouped', 'label': 'Desagrupado'},
      {'id': 'grouped', 'label': 'Agrupado'},
      {'id': 'round', 'label': 'Por ronda'},
      {'id': 'pass', 'label': 'Por pases'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dividir cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: modes.map((m) {
            final isSelected = _mode == m['id'];
            return ChoiceChip(
              label: Text(m['label'] as String),
              selected: isSelected,
              onSelected: (_) => setState(() => _mode = m['id'] as String),
              selectedColor: Colors.green.shade200,
            );
          }).toList(),
        ),
      ],
    );
  }
}
