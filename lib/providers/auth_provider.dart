import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? AuthRepository() {
    _subscription = _repository.authStateChanges.listen(
      (user) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object error) {
        _error = error;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<User?> _subscription;
  User? _currentUser;
  bool _isLoading = true;
  bool _isRegistering = false;
  Object? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isRegistering => _isRegistering;
  Object? get error => _error;

  Future<void> signIn({required String email, required String password}) =>
      _repository.signIn(email: email, password: password);

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
  }) async {
    _isRegistering = true;
    notifyListeners();
    try {
      await _repository.register(
        email: email,
        password: password,
        name: name,
        role: role,
        phone: phone,
      );
    } finally {
      _isRegistering = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _repository.sendPasswordResetEmail(email);

  Future<bool> hasSuperAdminClaim() => _repository.hasSuperAdminClaim();

  Future<void> updatePassword(String password) =>
      _repository.updatePassword(password);

  Future<void> signOut() => _repository.signOut();

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
