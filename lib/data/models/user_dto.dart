import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/constants.dart';

class UserEntity {
  final String id;
  final String email;
  final String displayName;
  final String? venueId;
  final bool active;
  final bool isTest;
  final DateTime? lastLoginAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    this.venueId,
    this.active = true,
    this.isTest = false,
    this.lastLoginAt,
  });

  factory UserEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserEntity(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      venueId: data['venueId'],
      active: data['active'] ?? true,
      isTest: data['isTest'] ?? false,
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'displayName': displayName,
    'venueId': venueId,
    'active': active,
    'isTest': isTest,
    'lastLoginAt': lastLoginAt,
  };
}

class VenueEntity {
  final String id;
  final String name;
  final String address;
  final double taxRate;
  final String currency;

  const VenueEntity({
    required this.id,
    required this.name,
    required this.address,
    this.taxRate = 0,
    this.currency = Constants.currencySymbol,
  });

  factory VenueEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VenueEntity(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] ?? Constants.currencySymbol,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'address': address,
    'taxRate': taxRate,
    'currency': currency,
  };
}