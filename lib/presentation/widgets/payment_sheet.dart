import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order_dto.dart';

class PaymentSheet extends ConsumerStatefulWidget {
  final double total;
  final Function(String paymentMethod) onPaid;
  final List<OrderItemEntity> items;
  final String tableNumber;

  const PaymentSheet({
    super.key, 
    required this.total, 
    required this.onPaid,
    required this.items,
    required this.tableNumber,
  });

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  String _method = 'cash';
  String _cashInput = '';
  double _change = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Cobro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(Formatters.currency(widget.total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Método de pago', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _methodChip('cash', '💵 Efectivo', Icons.payments),
                _methodChip('card', '💳 Tarjeta', Icons.credit_card),
                _methodChip('invitation', '🎁 Invitación', Icons.card_giftcard),
              ],
            ),
            if (_method == 'cash') ...[
              const SizedBox(height: 16),
              TextField(
                onChanged: (v) {
                  setState(() {
                    _cashInput = v;
                    final received = double.tryParse(v) ?? 0;
                    _change = received - widget.total;
                  });
                },
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Importe recibido',
                  prefixText: '€ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              if (_cashInput.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cambio: ${Formatters.currency(_change)}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _change >= 0 ? AppTheme.success : AppTheme.error)),
                  ],
                ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _canPay() ? _confirmPayment : null,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                child: const Text('Confirmar pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _methodChip(String value, String label, IconData icon) {
    final isSelected = _method == value;
    return ChoiceChip(
      label: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(label)]),
      selected: isSelected,
      onSelected: (_) => setState(() => _method = value),
      selectedColor: AppTheme.primaryLight.withOpacity(0.15),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? AppTheme.primary : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.divider)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  bool _canPay() {
    if (_method == 'cash') return _cashInput.isNotEmpty && (double.tryParse(_cashInput) ?? 0) >= widget.total;
    return true;
  }

  void _confirmPayment() {
    widget.onPaid(_method);
  }
}