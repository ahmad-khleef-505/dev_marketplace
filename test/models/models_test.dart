import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dev_marketplace/models/favorite_project.dart';
import 'package:dev_marketplace/models/project.dart';
import 'package:dev_marketplace/models/project_chat.dart';
import 'package:dev_marketplace/models/purchase_order.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ignore: subtype_of_sealed_class
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('Project model', () {
    test('deserializes supported fields and defaults missing values', () {
      final snapshot = MockDocumentSnapshot();
      when(() => snapshot.id).thenReturn('project-1');
      when(() => snapshot.data()).thenReturn({
        'title': 'Starter app',
        'price': 19,
        'techStack': ['Flutter'],
        'averageRating': 4.5,
      });

      final project = Project.fromFirestore(snapshot);

      expect(project.id, 'project-1');
      expect(project.title, 'Starter app');
      expect(project.price, 19);
      expect(project.techStack, ['Flutter']);
      expect(project.averageRating, 4.5);
      expect(project.status, 'pending');
      expect(project.developerId, isEmpty);
      expect(project.isEscrow, isFalse);
    });

    test('serializes its fields without including its document id', () {
      const project = Project(
        id: 'p1',
        developerId: 'd1',
        developerName: 'Dev',
        projectType: 'app',
        title: 'Title',
        description: '',
        language: '',
        category: '',
        price: 0,
        demoLink: '',
        imageUrl: '',
        techStack: [],
        averageRating: 0,
        ratingCount: 0,
        totalRating: 0,
        isEscrow: false,
        status: 'pending',
        views: 0,
      );
      final map = project.toFirestore();

      expect(map['title'], 'Title');
      expect(map['price'], 0);
      expect(map['techStack'], isEmpty);
      expect(map.containsKey('id'), isFalse);
    });
  });

  test('favorite model handles empty documents and serializes card data', () {
    final snapshot = MockDocumentSnapshot();
    when(() => snapshot.id).thenReturn('favorite-1');
    when(() => snapshot.data()).thenReturn(null);

    final favorite = FavoriteProject.fromFirestore(snapshot);
    expect(favorite.projectId, 'favorite-1');
    expect(favorite.title, 'مشروع');
    expect(favorite.price, 0);

    const saved = FavoriteProject(
      projectId: 'p1',
      title: 'App',
      developerUid: 'd1',
      developerName: 'Dev',
      price: 10,
      imageUrl: '',
      projectType: 'app',
      techStack: ['Flutter'],
      averageRating: 4,
      ratingCount: 2,
      description: '',
      demoLink: '',
      isEscrow: true,
      views: 5,
    );
    expect(saved.toFirestore()['projectId'], 'p1');
    expect(saved.toFirestore()['views'], 5);
  });

  test(
    'chat and message models deserialize missing, legacy, and timestamp data',
    () {
      final chatSnapshot = MockDocumentSnapshot();
      when(() => chatSnapshot.id).thenReturn('chat-1');
      when(() => chatSnapshot.data()).thenReturn(null);
      final chat = ProjectChat.fromFirestore(chatSnapshot);
      expect(chat.id, 'chat-1');
      expect(chat.projectId, isEmpty);

      final messageSnapshot = MockDocumentSnapshot();
      when(() => messageSnapshot.id).thenReturn('message-1');
      when(() => messageSnapshot.data()).thenReturn({
        'senderUid': 'user-1',
        'senderName': 'User',
        'text': 'Hello',
        'createdAt': Timestamp.fromDate(DateTime.utc(2025)),
      });
      final message = ProjectChatMessage.fromFirestore(messageSnapshot);
      expect(message.senderId, 'user-1');
      expect(message.text, 'Hello');
      expect(message.sentAt, DateTime.utc(2025).toLocal());
    },
  );

  test('purchase order supports optional and absent fields', () {
    final snapshot = MockDocumentSnapshot();
    when(() => snapshot.id).thenReturn('order-1');
    when(() => snapshot.data()).thenReturn({'amount': 10, 'reviewReason': ''});

    final order = PurchaseOrder.fromFirestore(snapshot);
    expect(order.amount, 10);
    expect(order.status, 'unknown');
    expect(order.currency, 'USD');
    expect(order.reviewReason, '');
    expect(order.createdAt, isNull);
  });
}
