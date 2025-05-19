import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRequest {
  final String id;
  final String userId;
  final String userRole;
  final String message;
  final String status;
  final DateTime timestamp;
  final String? userName;

  ChatRequest({
    required this.id,
    required this.userId,
    required this.userRole,
    required this.message,
    required this.status,
    required this.timestamp,
    this.userName,
  });

  factory ChatRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRequest(
      id: doc.id,
      userId: data['userId'] as String,
      userRole: data['userRole'] as String,
      message: data['message'] as String,
      status: data['status'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      userName: data['userName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userRole': userRole,
      'message': message,
      'status': status,
      'timestamp': timestamp,
      if (userName != null) 'userName': userName,
    };
  }

  // Getters for backward compatibility
  String get senderId => userId;
  String get senderType => userRole;
  String get senderName => userName ?? 'User';
  DateTime get createdAt => timestamp;
} 