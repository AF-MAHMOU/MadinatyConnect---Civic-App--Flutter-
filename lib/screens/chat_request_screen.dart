import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../models/chat_request.dart';
import '../utils/app_theme.dart';
import '../utils/app_localizations.dart';
import 'chat_screen.dart';

class ChatRequestScreen extends StatefulWidget {
  @override
  _ChatRequestScreenState createState() => _ChatRequestScreenState();
}

class _ChatRequestScreenState extends State<ChatRequestScreen> {
  final _messageController = TextEditingController();
  final _chatService = ChatService();
  final _userId = FirebaseAuth.instance.currentUser?.uid;
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      if (_userId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .get();
        
        if (mounted) {
          setState(() {
            _userRole = userDoc.data()?['role'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user role: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitChatRequest() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      await _chatService.createChatRequest(
        _messageController.text.trim(),
        userRole: _userRole ?? 'citizen',
      );
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat request sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send chat request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Help & Support')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message to admin',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _submitChatRequest,
                  child: Text('Send Request'),
                  style: AppTheme.primaryButton,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChatRequest>>(
              stream: _chatService.getUserChatRequests(_userId!, userRole: _userRole),
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
                    child: Text('No chat requests yet'),
                  );
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(request.message),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: ${request.status}',
                              style: TextStyle(
                                color: request.status == 'pending'
                                    ? Colors.orange
                                    : request.status == 'active'
                                        ? Colors.green
                                        : request.status == 'completed'
                                            ? Colors.grey
                                            : Colors.red,
                              ),
                            ),
                            Text(
                              'ID: ${request.id}',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: request.status == 'completed'
                            ? IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Delete Chat'),
                                    content: Text('Are you sure you want to delete this chat? This action cannot be undone.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          try {
                                            // Delete all messages in the chat
                                            final messagesQuery = await FirebaseFirestore.instance
                                                .collection('chats')
                                                .doc(request.id)
                                                .collection('messages')
                                                .get();
                                            
                                            final batch = FirebaseFirestore.instance.batch();
                                            for (var doc in messagesQuery.docs) {
                                              batch.delete(doc.reference);
                                            }
                                            
                                            // Delete the chat document itself
                                            batch.delete(FirebaseFirestore.instance
                                                .collection('chats')
                                                .doc(request.id));
                                            
                                            // Delete the chat request
                                            batch.delete(FirebaseFirestore.instance
                                                .collection('chat_requests')
                                                .doc(request.id));
                                            
                                            await batch.commit();

                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Chat deleted successfully')),
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Failed to delete chat: $e')),
                                              );
                                            }
                                          }
                                        },
                                        child: Text('Delete'),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : null,
                        onTap: () async {
                          print('Chat status: ${request.status}'); // Debug print
                          if (request.status == 'active') {
                            print('Navigating to chat with ID: ${request.id}'); // Debug print
                            try {
                              // Verify chat exists before navigation
                              final chatDoc = await FirebaseFirestore.instance
                                  .collection('chats')
                                  .doc(request.id)
                                  .get();
                              
                              if (!chatDoc.exists) {
                                throw Exception('Chat document not found');
                              }

                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      chatId: request.id,
                                      otherUserName: 'Admin',
                                      otherUserId: 'admin',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              print('Error navigating to chat: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error accessing chat: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('This chat is not active yet'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 