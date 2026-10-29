import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/project_chat.dart';

class ProjectChatRepository {
  ProjectChatRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  Future<String> createOrGetClientChat({
    required String projectId,
    required String clientUid,
    required String developerUid,
  }) async {
    final chatId = '${projectId}_$clientUid';
    final chatReference = _chats.doc(chatId);
    await _firestore.runTransaction((transaction) async {
      final chat = await transaction.get(chatReference);
      if (!chat.exists) {
        transaction.set(chatReference, {
          'projectId': projectId,
          'clientUid': clientUid,
          'developerUid': developerUid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
        });
        return;
      }

      final data = chat.data() ?? const <String, dynamic>{};
      if (data['projectId'] != projectId ||
          data['clientUid'] != clientUid ||
          data['developerUid'] != developerUid) {
        throw StateError('بيانات غرفة المحادثة غير متوافقة مع المشروع.');
      }
    });
    return chatId;
  }

  Stream<List<ProjectChatMessage>> watchMessages(String chatId) => _chats
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map(ProjectChatMessage.fromFirestore).toList(),
      );

  Stream<List<ProjectChat>> watchProjectConversations({
    required String projectId,
    required String developerUid,
    required bool isSuperAdmin,
  }) {
    Query<Map<String, dynamic>> query = _chats;
    if (!isSuperAdmin) {
      query = query
          .where('projectId', isEqualTo: projectId)
          .where('developerUid', isEqualTo: developerUid);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ProjectChat.fromFirestore).toList(),
        );
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final chatReference = _chats.doc(chatId);
    final messageReference = chatReference.collection('messages').doc();
    final sentAt = FieldValue.serverTimestamp();
    final batch = _firestore.batch()
      ..set(messageReference, {
        'senderId': senderId,
        'senderUid': senderId,
        'senderName': senderName,
        'text': text,
        'timestamp': sentAt,
        'createdAt': sentAt,
      })
      ..update(chatReference, {'lastMessage': text, 'updatedAt': sentAt});
    await batch.commit();
  }
}
