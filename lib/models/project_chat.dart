import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectChat {
  const ProjectChat({
    required this.id,
    required this.projectId,
    required this.clientUid,
    required this.developerUid,
  });

  final String id;
  final String projectId;
  final String clientUid;
  final String developerUid;

  factory ProjectChat.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return ProjectChat(
      id: document.id,
      projectId: data['projectId']?.toString() ?? '',
      clientUid: data['clientUid']?.toString() ?? '',
      developerUid: data['developerUid']?.toString() ?? '',
    );
  }
}

class ProjectChatMessage {
  const ProjectChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime? sentAt;

  factory ProjectChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final timestamp = data['timestamp'] ?? data['createdAt'];
    return ProjectChatMessage(
      id: document.id,
      senderId: (data['senderId'] ?? data['senderUid'])?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      sentAt: timestamp is Timestamp ? timestamp.toDate().toLocal() : null,
    );
  }
}
