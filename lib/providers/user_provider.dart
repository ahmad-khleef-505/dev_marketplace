import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/foundation.dart';

import '../repositories/user_repository.dart';
import 'auth_provider.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({required this.repository, required this.authProvider}) {
    authProvider.addListener(_handleAuthChange);
    _handleAuthChange();
  }

  final UserRepository repository;
  final AuthProvider authProvider;
  StreamSubscription<Map<String, dynamic>?>? _profileSubscription;
  String? _activeUserId;
  Map<String, dynamic>? _userData;
  Object? _error;
  bool _isLoading = true;
  bool _disposed = false;

  Map<String, dynamic>? get userData => _userData;
  Object? get error => _error;
  bool get isLoading => _isLoading;

  void _handleAuthChange() {
    final user = authProvider.currentUser;
    if (user?.uid == _activeUserId) {
      if (user != null &&
          _isLoading &&
          !authProvider.isRegistering &&
          _profileSubscription == null) {
        unawaited(_loadProfile(user));
      }
      return;
    }

    unawaited(_profileSubscription?.cancel());
    _profileSubscription = null;
    _activeUserId = user?.uid;
    _userData = null;
    _error = null;
    _isLoading = user != null;
    notifyListeners();

    if (user != null && !authProvider.isRegistering) {
      unawaited(_loadProfile(user));
    }
  }

  Future<void> _loadProfile(User user) async {
    try {
      await repository.ensureUserProfile(user);
      if (_disposed || _activeUserId != user.uid) return;

      _profileSubscription = repository
          .watchUserProfile(user.uid)
          .listen(
            (data) {
              _userData = data;
              _error = null;
              _isLoading = false;
              notifyListeners();
            },
            onError: (Object error) {
              _error = error;
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (error) {
      if (_disposed || _activeUserId != user.uid) return;
      _error = error;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() => authProvider.signOut();

  @override
  void dispose() {
    _disposed = true;
    authProvider.removeListener(_handleAuthChange);
    unawaited(_profileSubscription?.cancel());
    super.dispose();
  }
}
