import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/purchase_settings.dart';

class PurchaseService {
  PurchaseService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<Map<String, dynamic>> publicSettings() async {
    return {
      'shamCashWalletId': PurchaseSettings.shamCashWalletId,
      'adminWhatsAppPhone': PurchaseSettings.adminWhatsAppPhone,
      'currency': PurchaseSettings.currency,
    };
  }

  Future<Map<String, dynamic>> createOrder({
    required String projectId,
    required String projectTitle,
    required String developerName,
    required double amount,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Authentication required.');

    final projectSnapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .get(const GetOptions(source: Source.serverAndCache));
    if (!projectSnapshot.exists ||
        projectSnapshot.data()?['status'] != 'approved') {
      throw StateError('Project is not available for purchase.');
    }

    final project = projectSnapshot.data()!;
    final actualAmount = project['price'];
    if (actualAmount is! num || actualAmount.toDouble() != amount) {
      throw StateError(
        'Project price changed. Refresh the project and try again.',
      );
    }
    if (project['developerId'] == user.uid) {
      throw StateError('Developers cannot purchase their own project.');
    }

    final orderReference = await _firestore.collection('purchaseOrders').add({
      'clientUid': user.uid,
      'projectId': projectId,
      'projectTitle': projectTitle,
      'developerId': project['developerId'],
      'developerName': developerName,
      'amount': amount,
      'currency': PurchaseSettings.currency,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending_payment',
    });

    return {
      'orderId': orderReference.id,
      'clientName': user.displayName ?? user.email ?? user.uid,
      'projectTitle': projectTitle,
      'developerName': developerName,
      'amount': amount,
      'currency': PurchaseSettings.currency,
      'walletId': PurchaseSettings.shamCashWalletId,
      'adminWhatsAppPhone': PurchaseSettings.adminWhatsAppPhone,
      'status': 'pending_payment',
    };
  }

  Future<void> submitTransferNotice(String orderId) async {
    await _firestore.collection('purchaseOrders').doc(orderId).update({
      'status': 'pending_admin_review',
      'transferNoticeSubmittedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> reviewOrder({
    required String orderId,
    required String decision,
    String reason = '',
  }) async {
    final admin = _auth.currentUser;
    if (admin == null) throw StateError('Authentication required.');
    if (decision != 'approve' && decision != 'reject') {
      throw ArgumentError.value(decision, 'decision');
    }
    if (decision == 'reject' && reason.trim().isEmpty) {
      throw ArgumentError('A rejection reason is required.');
    }

    final orderReference = _firestore.collection('purchaseOrders').doc(orderId);
    return _firestore.runTransaction<bool>((transaction) async {
      final orderSnapshot = await transaction.get(orderReference);
      if (!orderSnapshot.exists ||
          orderSnapshot.data()?['status'] != 'pending_admin_review') {
        throw StateError('Order is missing or has already been reviewed.');
      }

      final order = orderSnapshot.data()!;
      final update = <String, dynamic>{
        'status': decision == 'approve' ? 'approved' : 'rejected',
        'reviewedBy': admin.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewReason': decision == 'reject' ? reason.trim() : null,
      };
      var contactAvailable = false;

      if (decision == 'approve') {
        final contactReference = _firestore
            .collection('projectPrivateContacts')
            .doc(order['projectId'] as String);
        final contactSnapshot = await transaction.get(contactReference);
        final contact = contactSnapshot.data();
        final phone = contact?['phone'];
        if (contactSnapshot.exists &&
            contact?['developerId'] == order['developerId'] &&
            phone is String &&
            phone.trim().length >= 6) {
          update['developerPhone'] = phone.trim();
          contactAvailable = true;
        }
      }

      transaction.update(orderReference, update);
      return contactAvailable;
    });
  }

  Future<Map<String, dynamic>> getDelivery(String orderId) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Authentication required.');
    final snapshot = await _firestore
        .collection('purchaseOrders')
        .doc(orderId)
        .get(const GetOptions(source: Source.serverAndCache));
    final order = snapshot.data();
    if (!snapshot.exists ||
        order?['clientUid'] != user.uid ||
        order?['status'] != 'approved') {
      throw StateError('Purchase is not approved for delivery.');
    }
    return {
      'developerName': order?['developerName'] ?? 'مطور',
      'developerPhone': order?['developerPhone'] is String
          ? (order?['developerPhone'] as String).trim()
          : null,
      'projectTitle': order?['projectTitle'] ?? 'مشروع',
    };
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> latestOrder({
    required String clientUid,
    required String projectId,
  }) async {
    final result = await _firestore
        .collection('purchaseOrders')
        .where('clientUid', isEqualTo: clientUid)
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get(const GetOptions(source: Source.serverAndCache));
    return result.docs.isEmpty ? null : result.docs.first;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> readOrder(String orderId) {
    return _firestore
        .collection('purchaseOrders')
        .doc(orderId)
        .get(const GetOptions(source: Source.serverAndCache));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> allPurchaseOrders() {
    return _firestore
        .collection('purchaseOrders')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingPurchaseOrders() {
    return _firestore
        .collection('purchaseOrders')
        .where('status', isEqualTo: 'pending_admin_review')
        .orderBy('transferNoticeSubmittedAt')
        .limit(50)
        .snapshots();
  }
}
