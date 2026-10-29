import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  const Project({
    required this.id,
    required this.developerId,
    required this.developerName,
    required this.projectType,
    required this.title,
    required this.description,
    required this.language,
    required this.category,
    required this.price,
    required this.demoLink,
    required this.imageUrl,
    required this.techStack,
    required this.averageRating,
    required this.ratingCount,
    required this.totalRating,
    required this.isEscrow,
    required this.status,
    required this.views,
  });

  final String id;
  final String developerId;
  final String developerName;
  final String projectType;
  final String title;
  final String description;
  final String language;
  final String category;
  final double price;
  final String demoLink;
  final String imageUrl;
  final List<String> techStack;
  final double averageRating;
  final int ratingCount;
  final int totalRating;
  final bool isEscrow;
  final String status;
  final int views;

  factory Project.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return Project(
      id: document.id,
      developerId: data['developerId']?.toString() ?? '',
      developerName: data['developerName']?.toString() ?? 'مطور',
      projectType: data['projectType']?.toString() ?? 'app',
      title: data['title']?.toString() ?? 'مشروع بدون عنوان',
      description: data['description']?.toString() ?? '',
      language: data['language']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      demoLink: data['demoLink']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      techStack: List<String>.from(data['techStack'] as List? ?? const []),
      averageRating:
          (data['averageRating'] as num?)?.toDouble() ??
          (data['rating'] as num?)?.toDouble() ??
          0,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      totalRating: (data['totalRating'] as num?)?.toInt() ?? 0,
      isEscrow: data['isEscrow'] == true,
      status: data['status']?.toString() ?? 'pending',
      views: (data['views'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'developerId': developerId,
    'developerName': developerName,
    'projectType': projectType,
    'title': title,
    'description': description,
    'language': language,
    'category': category,
    'price': price,
    'demoLink': demoLink,
    'imageUrl': imageUrl,
    'techStack': techStack,
    'rating': averageRating,
    'averageRating': averageRating,
    'totalRating': totalRating,
    'ratingCount': ratingCount,
    'isEscrow': isEscrow,
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
    'views': views,
    'inquiries': 0,
  };
}
