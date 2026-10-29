import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/favorite_project.dart';
import '../repositories/favorite_repository.dart';
import 'auth_provider.dart';

class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider({required this.repository, required this.authProvider}) {
    authProvider.addListener(_handleAuthChange);
    _handleAuthChange();
  }

  final FavoriteRepository repository;
  final AuthProvider authProvider;
  StreamSubscription<List<FavoriteProject>>? _subscription;
  List<FavoriteProject> _favorites = const [];
  bool _isLoading = true;
  Object? _error;

  List<FavoriteProject> get favorites => List.unmodifiable(_favorites);
  bool get isLoading => _isLoading;
  Object? get error => _error;

  bool isFavorite(String projectId) =>
      _favorites.any((favorite) => favorite.projectId == projectId);

  void _handleAuthChange() {
    unawaited(_subscription?.cancel());
    _favorites = const [];
    _error = null;
    final userId = authProvider.currentUser?.uid;
    _isLoading = userId != null;
    notifyListeners();

    if (userId == null) return;
    _subscription = repository
        .watchFavorites(userId)
        .listen(
          (favorites) {
            _favorites = favorites;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            _error = error;
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> toggleFavorite(FavoriteProject project) async {
    final userId = authProvider.currentUser?.uid;
    if (userId == null) {
      throw StateError('سجّل الدخول لإضافة المشروع للمفضلة.');
    }

    await repository.setFavorite(
      userId,
      project,
      isFavorite: !isFavorite(project.projectId),
    );
  }

  @override
  void dispose() {
    authProvider.removeListener(_handleAuthChange);
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
