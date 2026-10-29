import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/favorite_project.dart';

class FavoriteRepository {
  FavoriteRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _favorites(String userId) =>
      _firestore.collection('users').doc(userId).collection('favorites');

  Stream<List<FavoriteProject>> watchFavorites(String userId) =>
      _favorites(userId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map(FavoriteProject.fromFirestore).toList(),
          );

  Future<void> setFavorite(
    String userId,
    FavoriteProject project, {
    required bool isFavorite,
  }) async {
    final document = _favorites(userId).doc(project.projectId);
    if (isFavorite) {
      await document.set(project.toFirestore());
    } else {
      await document.delete();
    }
  }
}
