import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseOrder {
  const PurchaseOrder({
    required this.projectTitle,
    required this.status,
    required this.amount,
    required this.currency,
    required this.createdAt,
    required this.reviewReason,
  });

  final String projectTitle;
  final String status;
  final double? amount;
  final String currency;
  final DateTime? createdAt;
  final String? reviewReason;

  factory PurchaseOrder.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final timestamp = data['createdAt'];
    return PurchaseOrder(
      projectTitle: data['projectTitle']?.toString() ?? 'مشروع بدون عنوان',
      status: data['status']?.toString() ?? 'unknown',
      amount: (data['amount'] as num?)?.toDouble(),
      currency: data['currency']?.toString() ?? 'USD',
      createdAt: timestamp is Timestamp ? timestamp.toDate().toLocal() : null,
      reviewReason: data['reviewReason']?.toString(),
    );
  }
}
