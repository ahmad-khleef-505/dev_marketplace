import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/project.dart';
import '../services/rating_calculator.dart';

class ProjectCursor {
  const ProjectCursor._(this._document);

  final DocumentSnapshot<Map<String, dynamic>> _document;
}

class ProjectPage {
  const ProjectPage({
    required this.projects,
    required this.cursor,
    required this.hasMore,
  });

  final List<Project> projects;
  final ProjectCursor? cursor;
  final bool hasMore;
}

class ProjectRepository {
  ProjectRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Project?> getProject(String projectId) async {
    final snapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.exists ? Project.fromFirestore(snapshot) : null;
  }

  Stream<Project?> watchProject(String projectId) => _firestore
      .collection('projects')
      .doc(projectId)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists ? Project.fromFirestore(snapshot) : null,
      );

  Stream<bool> watchHasRated(String projectId, String userId) => _firestore
      .collection('projects')
      .doc(projectId)
      .collection('ratings')
      .doc(userId)
      .snapshots()
      .map((snapshot) => snapshot.exists);

  Stream<List<Project>> watchDeveloperApprovedProjects(String developerId) =>
      _firestore
          .collection('projects')
          .where('developerId', isEqualTo: developerId)
          .where('status', isEqualTo: 'approved')
          .limit(50)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(Project.fromFirestore).toList());

  Future<void> submitRating({
    required String projectId,
    required String userId,
    required int rating,
  }) async {
    final project = _firestore.collection('projects').doc(projectId);
    final projectRating = project.collection('ratings').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final projectSnapshot = await transaction.get(project);
      final ratingSnapshot = await transaction.get(projectRating);
      if (!projectSnapshot.exists) {
        throw StateError('المشروع غير موجود.');
      }
      if (ratingSnapshot.exists) {
        throw StateError('سبق أن قيّمت هذا المشروع.');
      }
      final projectData = projectSnapshot.data()!;
      if (projectData['status'] != 'approved') {
        throw StateError('لا يمكن تقييم مشروع غير منشور.');
      }
      if (projectData['developerId'] == userId) {
        throw StateError('لا يمكنك تقييم مشروعك الخاص.');
      }

      final totalRating = (projectData['totalRating'] as num?)?.toDouble() ?? 0;
      final ratingCount = (projectData['ratingCount'] as num?)?.toInt() ?? 0;
      final averageRating = RatingCalculator.nextAverage(
        totalRating: totalRating,
        ratingCount: ratingCount,
        newRating: rating,
      );
      transaction.set(projectRating, {
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(project, {
        'totalRating': FieldValue.increment(rating),
        'ratingCount': FieldValue.increment(1),
        'averageRating': averageRating,
        'rating': averageRating,
      });
    });
  }

  Query<Map<String, dynamic>> _approvedProjectsQuery({
    required String category,
    required double minimumPrice,
    required double maximumPrice,
    required Set<String> technologies,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('projects')
        .where('status', isEqualTo: 'approved')
        .where('category', isEqualTo: category)
        .where('price', isGreaterThanOrEqualTo: minimumPrice)
        .where('price', isLessThanOrEqualTo: maximumPrice);

    if (technologies.isNotEmpty) {
      query = query.where('techStack', arrayContainsAny: technologies.toList());
    }

    return query.orderBy('price').orderBy('averageRating', descending: true);
  }

  Stream<ProjectPage> getApprovedProjects({
    required String category,
    required double minimumPrice,
    required double maximumPrice,
    required Set<String> technologies,
    required int limit,
  }) {
    return _approvedProjectsQuery(
          category: category,
          minimumPrice: minimumPrice,
          maximumPrice: maximumPrice,
          technologies: technologies,
        )
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => ProjectPage(
            projects: snapshot.docs.map(Project.fromFirestore).toList(),
            cursor: snapshot.docs.isEmpty
                ? null
                : ProjectCursor._(snapshot.docs.last),
            hasMore: snapshot.docs.length == limit,
          ),
        );
  }

  Future<List<Project>> getApprovedProjectsByType(String projectType) async {
    final snapshot = await _firestore
        .collection('projects')
        .where('status', isEqualTo: 'approved')
        .where('projectType', isEqualTo: projectType)
        .limit(50)
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs.map(Project.fromFirestore).toList();
  }

  Future<ProjectPage> getNextApprovedProjects({
    required String category,
    required double minimumPrice,
    required double maximumPrice,
    required Set<String> technologies,
    required int limit,
    required ProjectCursor cursor,
  }) async {
    final snapshot =
        await _approvedProjectsQuery(
              category: category,
              minimumPrice: minimumPrice,
              maximumPrice: maximumPrice,
              technologies: technologies,
            )
            .startAfterDocument(cursor._document)
            .limit(limit)
            .get(const GetOptions(source: Source.serverAndCache));

    return ProjectPage(
      projects: snapshot.docs.map(Project.fromFirestore).toList(),
      cursor: snapshot.docs.isEmpty
          ? null
          : ProjectCursor._(snapshot.docs.last),
      hasMore: snapshot.docs.length == limit,
    );
  }

  Future<void> addProject({
    required Project project,
    required String developerPhone,
  }) async {
    final projectRef = _firestore.collection('projects').doc();
    final batch = _firestore.batch()
      ..set(projectRef, project.toFirestore())
      ..set(
        _firestore.collection('projectPrivateContacts').doc(projectRef.id),
        {
          'developerId': project.developerId,
          'phone': developerPhone,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      )
      ..set(
        _firestore
            .collection('publicDeveloperProfiles')
            .doc(project.developerId),
        {'uid': project.developerId, 'name': project.developerName},
        SetOptions(merge: true),
      );
    await batch.commit();
  }

  Future<void> recordView(String projectId) => _firestore
      .collection('projects')
      .doc(projectId)
      .update({'views': FieldValue.increment(1)});
}
