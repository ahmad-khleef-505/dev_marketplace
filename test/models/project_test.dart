import 'package:dev_marketplace/models/favorite_project.dart';
import 'package:dev_marketplace/models/project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('project maps its typed fields to Firestore fields', () {
    const project = Project(
      id: '',
      developerId: 'developer-1',
      developerName: 'Developer',
      projectType: 'app',
      title: 'Sample app',
      description: 'A sample project',
      language: 'Dart',
      category: 'تطبيق جوال',
      price: 250,
      demoLink: 'https://example.com/demo',
      imageUrl: 'https://example.com/image.jpg',
      techStack: ['Flutter', 'Firebase'],
      averageRating: 4.5,
      ratingCount: 2,
      totalRating: 9,
      isEscrow: true,
      status: 'pending',
      views: 3,
    );

    final data = project.toFirestore();

    expect(data['developerId'], 'developer-1');
    expect(data['price'], 250);
    expect(data['techStack'], ['Flutter', 'Firebase']);
    expect(data['averageRating'], 4.5);
    expect(data['status'], 'pending');
    expect(data['createdAt'], isNotNull);
  });

  test('favorite projects preserve all card details', () {
    const favorite = FavoriteProject(
      projectId: 'project-1',
      title: 'Sample app',
      developerUid: 'developer-1',
      developerName: 'Developer',
      price: 250,
      imageUrl: 'https://example.com/image.jpg',
      projectType: 'app',
      techStack: ['Flutter'],
      averageRating: 4.5,
      ratingCount: 2,
      description: 'A sample project',
      demoLink: 'https://example.com/demo',
      isEscrow: true,
      views: 3,
    );

    final data = favorite.toFirestore();

    expect(data['projectId'], 'project-1');
    expect(data['developerUid'], 'developer-1');
    expect(data['title'], 'Sample app');
    expect(data['views'], 3);
    expect(data['createdAt'], isNotNull);
  });
}
