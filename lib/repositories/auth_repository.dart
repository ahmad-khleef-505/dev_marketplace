import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<bool> hasSuperAdminClaim() async =>
      (await _auth.currentUser?.getIdTokenResult())?.claims?['superAdmin'] ==
      true;

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('تعذر إنشاء حساب المستخدم.');
    }

    final userReference = _firestore.collection('users').doc(user.uid);
    final batch = _firestore.batch()
      ..set(userReference, {
        'uid': user.uid,
        'name': name,
        'email': email,
        'role': role,
        'userType': role == 'developer' ? 'developer' : 'client',
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });
    if (role == 'developer') {
      batch.set(
        _firestore.collection('publicDeveloperProfiles').doc(user.uid),
        {'uid': user.uid, 'name': name, 'bio': '', 'photoUrl': ''},
      );
    }
    await batch.commit();
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> updatePassword(String password) =>
      _auth.currentUser!.updatePassword(password);

  Future<void> signOut() => _auth.signOut();
}
