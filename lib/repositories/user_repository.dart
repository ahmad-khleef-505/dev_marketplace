import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> ensureUserProfile(User user) async {
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw StateError('لا يمكن إنشاء ملف الحساب من دون بريد إلكتروني.');
    }

    final userReference = _firestore.collection('users').doc(user.uid);
    final snapshot = await userReference.get(
      const GetOptions(source: Source.serverAndCache),
    );
    if (snapshot.exists) return;

    final name = user.displayName?.trim();
    await userReference.set({
      'uid': user.uid,
      'email': email,
      'role': 'client',
      'userType': 'client',
      'createdAt': FieldValue.serverTimestamp(),
      if (name != null && name.isNotEmpty) 'name': name,
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.data();
  }

  Stream<Map<String, dynamic>?> watchUserProfile(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((snapshot) => snapshot.data());

  Stream<Map<String, dynamic>?> watchPublicDeveloperProfile(
    String developerId,
  ) => _firestore
      .collection('publicDeveloperProfiles')
      .doc(developerId)
      .snapshots()
      .map((snapshot) => snapshot.data());
}
