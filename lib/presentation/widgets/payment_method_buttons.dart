import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/constants.dart';

class PaymentMethodButtons extends ConsumerStatefulWidget {
  const PaymentMethodButtons({super.key});

  @override
  ConsumerState<PaymentMethodButtons> createState() => _PaymentMethodButtonsState();
}

class _PaymentMethodButtonsState extends ConsumerState<PaymentMethodButtons> {
  String _selectedMethod = '';

  @override
  Widget build(BuildContext context) {
    final methods = [
      {'id': Constants.methodCard, 'label': '💳 Tarjeta', 'color': Colors.blue.shade100},
      {'id': Constants.methodCash, 'label': '💵 Efectivo', 'color': Colors.green.shade100},
      {'id': Constants.methodCashNoChange, 'label': '💵 Sin cambio', 'color': Colors.green.shade50},
      {'id': Constants.methodOther, 'label': '📝 Otro', 'color': Colors.orange.shade100},
      {'id': Constants.methodInvitation, 'label': '🎁 Invitación', 'color': Colors.purple.shade100},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: methods.map((m) {
        final isSelected = _selectedMethod == m['id'];
        return ChoiceChip(
          label: Text(m['label'] as String),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedMethod = m['id'] as String),
          backgroundColor: Colors.grey.shade100,
          selectedColor: Colors.green.shade200,
        );
      }).toList(),
    );
  }
}
