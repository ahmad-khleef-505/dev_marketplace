import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteProject {
  const FavoriteProject({
    required this.projectId,
    required this.title,
    required this.developerUid,
    required this.developerName,
    required this.price,
    required this.imageUrl,
    required this.projectType,
    required this.techStack,
    required this.averageRating,
    required this.ratingCount,
    required this.description,
    required this.demoLink,
    required this.isEscrow,
    required this.views,
  });

  final String projectId;
  final String title;
  final String developerUid;
  final String developerName;
  final double price;
  final String imageUrl;
  final String projectType;
  final List<String> techStack;
  final double averageRating;
  final int ratingCount;
  final String description;
  final String demoLink;
  final bool isEscrow;
  final int views;

  factory FavoriteProject.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return FavoriteProject(
      projectId: data['projectId']?.toString() ?? document.id,
      title: data['title']?.toString() ?? 'مشروع',
      developerUid: data['developerUid']?.toString() ?? '',
      developerName: data['developerName']?.toString() ?? 'مطور',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      imageUrl: data['imageUrl']?.toString() ?? '',
      projectType: data['projectType']?.toString() ?? 'app',
      techStack: List<String>.from(data['techStack'] as List? ?? const []),
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      description: data['description']?.toString() ?? '',
      demoLink: data['demoLink']?.toString() ?? '',
      isEscrow: data['isEscrow'] == true,
      views: (data['views'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'projectId': projectId,
    'createdAt': FieldValue.serverTimestamp(),
    'title': title,
    'developerUid': developerUid,
    'developerName': developerName,
    'price': price,
    'imageUrl': imageUrl,
    'projectType': projectType,
    'techStack': techStack,
    'averageRating': averageRating,
    'ratingCount': ratingCount,
    'description': description,
    'demoLink': demoLink,
    'isEscrow': isEscrow,
    'views': views,
  };
}
