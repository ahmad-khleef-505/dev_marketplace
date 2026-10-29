import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/purchase_order.dart';

class PurchaseOrderRepository {
  PurchaseOrderRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<PurchaseOrder>> watchClientOrders(String clientUid) => _firestore
      .collection('purchaseOrders')
      .where('clientUid', isEqualTo: clientUid)
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(PurchaseOrder.fromFirestore).toList(),
      );
}
