import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import '../../models/chat_request.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_localizations.dart';
import '../chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminChatRequests extends StatefulWidget {
  @override
  _AdminChatRequestsState createState() => _AdminChatRequestsState();
}

class _AdminChatRequestsState extends State<AdminChatRequests> {
  final _chatService = ChatService();
  final _auth = FirebaseAuth.instance;

  Future<void> _handleChatRequest(ChatRequest request, String action) async {
    try {
      final adminId = _auth.currentUser?.uid;
      if (adminId == null) throw Exception('Admin not authenticated');

      print('Handling chat request: ${request.id} with action: $action'); // Debug print

      // First update the chat request status
      await _chatService.updateChatRequestStatus(request.id, action == 'accepted' ? 'active' : 'rejected');
      print('Updated chat request status to: ${action == 'accepted' ? 'active' : 'rejected'}'); // Debug print
      
      if (action == 'accepted') {
        // Create a new chat document when accepting the request
        final chatDocRef = await FirebaseFirestore.instance.collection('chats').doc(request.id);
        final chatData = {
          'participants': [request.senderId, adminId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': request.message,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'status': 'active',
          'adminId': adminId,
          'citizenId': request.senderId,
          'chatRequestId': request.id
        };
        
        print('Creating chat document with data: $chatData'); // Debug print
        await chatDocRef.set(chatData);

        // Create initial system message
        final systemMessage = {
          'senderId': 'system',
          'senderName': 'System',
          'message': 'Chat started',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': true
        };
        
        print('Adding system message: $systemMessage'); // Debug print
        await chatDocRef.collection('messages').add(systemMessage);

        if (!mounted) return;
        
        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: request.id,
              otherUserName: request.senderName,
              otherUserId: request.senderId,
            ),
          ),
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'accepted'
                  ? 'Chat request accepted'
                  : 'Chat request rejected',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error handling chat request: $e'); // Debug print
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update chat request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('chat_requests')),
      ),
      body: StreamBuilder<List<ChatRequest>>(
        stream: _chatService.getAdminChatRequests(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return Center(
              child: Text(localizations.translate('no_pending_requests')),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            request.senderType == 'citizen'
                                ? Icons.person
                                : Icons.business,
                            color: AppTheme.primaryBlue,
                          ),
                          SizedBox(width: 8),
                          Text(
                            request.senderName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Spacer(),
                          Text(
                            request.senderType.toUpperCase(),
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        request.message,
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '${localizations.translate('sent_at')}: ${request.createdAt.toString()}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _handleChatRequest(request, 'rejected'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text(localizations.translate('reject')),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () => _handleChatRequest(request, 'accepted'),
                            style: AppTheme.primaryButton,
                            child: Text(localizations.translate('accept')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 