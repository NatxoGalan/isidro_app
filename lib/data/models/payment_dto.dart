import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/constants.dart';

enum PaymentMethod { card, cash, cashNoChange, other, invitation }

class PaymentEntity {
  final String id;
  final String orderId;
  final PaymentMethod method;
  final double amount;
  final double change;
  final double? receivedAmount;
  final String printerTarget;
  final DateTime createdAt;
  final String cashierId;

  const PaymentEntity({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
    required this.change,
    this.receivedAmount,
    required this.printerTarget,
    required this.createdAt,
    required this.cashierId,
  });

  factory PaymentEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentEntity(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      method: PaymentMethod.values.firstWhere(
        (m) => m.name == data['method'],
        orElse: () => PaymentMethod.card,
      ),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      change: (data['change'] as num?)?.toDouble() ?? 0.0,
      receivedAmount: (data['receivedAmount'] as num?)?.toDouble(),
      printerTarget: data['printerTarget'] ?? Constants.printerKitchen,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cashierId: data['cashierId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'orderId': orderId,
    'method': method.name,
    'amount': amount,
    'change': change,
    'receivedAmount': receivedAmount,
    'printerTarget': printerTarget,
    'createdAt': createdAt,
    'cashierId': cashierId,
  };
}
