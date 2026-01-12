import 'package:flutter/foundation.dart';

/// Model representing a professional service booking
@immutable
class ServiceBooking {
  const ServiceBooking({
    required this.id,
    required this.userId,
    required this.professionalAccountId,
    required this.professionalName,
    required this.amount,
    required this.currency,
    required this.status,
    this.applicationFee,
    this.paymentIntentId,
    this.hours,
    this.serviceDate,
    this.notes,
    this.createdAt,
    this.completedAt,
  });

  final String id;
  final String userId;
  final String professionalAccountId;
  final String professionalName;
  final double amount;
  final String currency;
  final String status; // pending, confirmed, completed, canceled
  final double? applicationFee;
  final String? paymentIntentId;
  final double? hours;
  final DateTime? serviceDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? completedAt;

  /// Create from Firestore document
  factory ServiceBooking.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return ServiceBooking(
      id: id,
      userId: data['userId'] as String? ?? '',
      professionalAccountId: data['professionalAccountId'] as String? ?? '',
      professionalName: data['professionalName'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'usd',
      status: data['status'] as String? ?? 'pending',
      applicationFee: (data['applicationFee'] as num?)?.toDouble(),
      paymentIntentId: data['paymentIntentId'] as String?,
      hours: (data['hours'] as num?)?.toDouble(),
      serviceDate: data['serviceDate'] != null
          ? (data['serviceDate'] as dynamic).toDate() as DateTime?
          : null,
      notes: data['notes'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate() as DateTime?
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as dynamic).toDate() as DateTime?
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'professionalAccountId': professionalAccountId,
      'professionalName': professionalName,
      'amount': amount,
      'currency': currency,
      'status': status,
      if (applicationFee != null) 'applicationFee': applicationFee,
      if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
      if (hours != null) 'hours': hours,
      if (serviceDate != null) 'serviceDate': serviceDate,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'createdAt': createdAt,
      if (completedAt != null) 'completedAt': completedAt,
    };
  }

  /// Check if booking is confirmed
  bool get isConfirmed => status == 'confirmed' || status == 'completed';

  /// Check if booking is pending payment
  bool get isPending => status == 'pending';

  /// Format amount as currency string
  String get formattedAmount {
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Format total amount including fees
  String get formattedTotal {
    final total = amount + (applicationFee ?? 0.0);
    return '\$${total.toStringAsFixed(2)}';
  }
}

