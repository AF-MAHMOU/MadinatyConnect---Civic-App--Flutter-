import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_request.dart';
import '../models/chat_message.dart';
import 'text_moderation_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new chat request
  Future<void> createChatRequest(String message, {String? userRole}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Check for profanity
    final isProfane = await TextModerationService.isProfane(message);
    if (isProfane) {
      throw Exception('Your message contains inappropriate content. Please revise your message.');
    }

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userName = userDoc.data()?['name'] ?? 'User';

    final chatRequest = {
      'userId': userId,
      'userRole': userRole ?? 'citizen',
      'userName': userName,
      'message': message,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('chat_requests').add(chatRequest);
  }

  // Get chat requests for admin
  Stream<List<ChatRequest>> getAdminChatRequests() {
    return _firestore
        .collection('chat_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRequest.fromFirestore(doc))
            .toList());
  }

  // Get chat requests for a specific user
  Stream<List<ChatRequest>> getUserChatRequests(String userId, {String? userRole}) {
    return _firestore
        .collection('chat_requests')
        .where('userId', isEqualTo: userId)
        .where('userRole', isEqualTo: userRole ?? 'citizen')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRequest.fromFirestore(doc))
            .toList());
  }

  // Update chat request status
  Future<void> updateChatRequestStatus(String chatId, String status) async {
    await _firestore
        .collection('chat_requests')
        .doc(chatId)
        .update({'status': status});
  }

  // Send a message
  Future<void> sendMessage(String chatId, String message) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Check for profanity
    final isProfane = await TextModerationService.isProfane(message);
    if (isProfane) {
      throw Exception('Your message contains inappropriate content. Please revise your message.');
    }

    // Filter profanity from the message
    final filteredMessage = await TextModerationService.filterProfanity(message);

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userName = userDoc.data()?['name'] ?? 'User';

    final chatMessage = {
      'senderId': userId,
      'senderName': userName,
      'message': filteredMessage,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(chatMessage);
  }

  // Get messages for a specific chat
  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ChatMessage(
              id: doc.id,
              chatId: chatId,
              senderId: data['senderId'] as String,
              senderName: data['senderName'] as String,
              message: data['message'] as String,
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              isRead: data['isRead'] as bool,
            );
          }).toList();
        });
  }

  // Mark messages as read (manual call)
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final messagesQuery = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in messagesQuery.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
} 