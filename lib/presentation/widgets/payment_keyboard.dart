import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentKeyboard extends ConsumerStatefulWidget {
  const PaymentKeyboard({super.key});

  @override
  ConsumerState<PaymentKeyboard> createState() => _PaymentKeyboardState();
}

class _PaymentKeyboardState extends ConsumerState<PaymentKeyboard> {
  String _amount = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _amount.isEmpty ? '0.00' : _amount,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...List.generate(3, (row) {
          return Row(
            children: List.generate(3, (col) {
              final num = row * 3 + col + 1;
              return Expanded(child: _numButton('$num'));
            }),
          );
        }),
        Row(
          children: [
            const Spacer(),
            Expanded(child: _numButton('.')),
            Expanded(child: _numButton('C')),
            Expanded(child: _numButton('Borrar')),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _numButton(String value) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            if (value == 'C') {
              _amount = '';
            } else if (value == 'Borrar') {
              if (_amount.isNotEmpty) {
                _amount = _amount.substring(0, _amount.length - 1);
              }
            } else {
              _amount += value;
            }
          });
        },
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
        child: Text(value, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
