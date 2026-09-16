import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../providers/cart_provider.dart';
import '../widgets/invoice_summary.dart';
import '../widgets/split_selector.dart';
import '../widgets/payment_method_buttons.dart';
import '../widgets/payment_keyboard.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String tableId;

  const CheckoutScreen({super.key, required this.tableId});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final subtotal = cart.subtotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Cobro'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InvoiceSummary(),
              const SizedBox(height: AppSizes.md),
              const Divider(),
              const SplitSelector(),
              const SizedBox(height: AppSizes.md),
              const Divider(),
              const PaymentMethodButtons(),
              const SizedBox(height: AppSizes.md),
              if (cart.items.any((i) => i.quantity > 0)) ...[
                const Divider(),
                const PaymentKeyboard(),
              ],
              const SizedBox(height: AppSizes.xl),
              SizedBox(
                height: AppSizes.touchTargetOptimal,
                child: ElevatedButton(
                  onPressed: subtotal > 0 ? () => _processPayment(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('CONFIRMAR PAGO ${Formatters.currency(subtotal)}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processPayment(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Procesando pago...')),
    );
  }
}
