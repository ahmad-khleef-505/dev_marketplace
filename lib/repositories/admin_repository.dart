import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnalyticsSummary {
  const AdminAnalyticsSummary({
    required this.usersCount,
    required this.projectsCount,
    required this.ordersCount,
    required this.approvedPriceTotal,
  });

  final int usersCount;
  final int projectsCount;
  final int ordersCount;
  final double approvedPriceTotal;
}

class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<AdminAnalyticsSummary> getAnalytics() async {
    final results = await Future.wait<Object>([
      _firestore.collection('users').count().get(),
      _firestore.collection('projects').count().get(),
      _firestore.collection('purchaseOrders').count().get(),
      _firestore
          .collection('projects')
          .where('status', isEqualTo: 'approved')
          .get(const GetOptions(source: Source.serverAndCache)),
    ]);

    final approvedProjects = results[3] as QuerySnapshot<Map<String, dynamic>>;
    final approvedPriceTotal = approvedProjects.docs.fold<double>(0, (
      total,
      project,
    ) {
      final price = project.data()['price'];
      return total + (price is num ? price.toDouble() : 0);
    });

    return AdminAnalyticsSummary(
      usersCount: (results[0] as AggregateQuerySnapshot).count ?? 0,
      projectsCount: (results[1] as AggregateQuerySnapshot).count ?? 0,
      ordersCount: (results[2] as AggregateQuerySnapshot).count ?? 0,
      approvedPriceTotal: approvedPriceTotal,
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchProjects(String status) =>
      _firestore
          .collection('projects')
          .where('status', isEqualTo: status)
          .limit(50)
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUsers() =>
      _firestore.collection('users').limit(100).snapshots();

  Future<void> updateProjectStatus(String id, String status) =>
      _firestore.collection('projects').doc(id).update({'status': status});

  Future<void> updateProjectDetails({
    required String id,
    required String title,
    required String description,
    required double price,
    required String status,
  }) => _firestore.collection('projects').doc(id).update({
    'title': title,
    'description': description,
    'price': price,
    'status': status,
  });

  Future<void> deleteProject(String id) =>
      _firestore.collection('projects').doc(id).delete();

  Future<void> updateUserType(String id, String userType) =>
      _firestore.collection('users').doc(id).update({'userType': userType});

  Future<void> deleteUser(String id) =>
      _firestore.collection('users').doc(id).delete();

  Future<Map<String, dynamic>?> getUser(String id) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(id)
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.data();
  }

  Future<String?> getDeveloperPhone(String projectId) async {
    final snapshot = await _firestore
        .collection('projectPrivateContacts')
        .doc(projectId)
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.data()?['phone']?.toString();
  }
}
