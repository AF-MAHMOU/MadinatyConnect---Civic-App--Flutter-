import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import '../utils/app_theme.dart';
import '../utils/app_localizations.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String otherUserId;

  ChatScreen({
    required this.chatId,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _chatService = ChatService();
  final _userId = FirebaseAuth.instance.currentUser?.uid;
  final _scrollController = ScrollController();
  bool _isAdmin = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _checkUserRole();
      if (_userId != null) {
        await _chatService.markMessagesAsRead(widget.chatId, _userId!);
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize chat: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkUserRole() async {
    if (_userId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
        if (mounted) {
          setState(() {
            _isAdmin = userDoc.data()?['role'] == 'admin';
          });
        }
      } catch (e) {
        print('Error checking user role: $e');
        // Don't throw, just continue with isAdmin = false
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      await _chatService.sendMessage(
        widget.chatId,
        text.trim(),
      );
      
      _messageController.clear();
      
      // Scroll to bottom after sending message
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      String errorMessage = 'Failed to send message';
      if (e.toString().contains('inappropriate content')) {
        errorMessage = 'Your message contains inappropriate content. Please revise your message.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Future<void> _endChat() async {
    try {
      // Update chat status
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({'status': 'completed'});
      
      // Update chat request status
      await _chatService.updateChatRequestStatus(widget.chatId, 'completed');
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat ended successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to end chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.otherUserName)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.otherUserName)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Colors.red)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _initialize();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            StreamBuilder<DocumentSnapshot>(
              stream: widget.otherUserId.isNotEmpty && widget.otherUserId != 'admin'
                  ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.otherUserId)
                      .snapshots()
                  : null,
              builder: (context, snapshot) {
                if (!snapshot.hasData || widget.otherUserId.isEmpty || widget.otherUserId == 'admin') {
                  return SizedBox.shrink();
                }
                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                final isOnline = userData?['isOnline'] ?? false;
                return Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? Colors.green : Colors.grey,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('End Chat'),
                  content: Text('Are you sure you want to end this chat?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _endChat();
                      },
                      child: Text('End Chat'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .snapshots(),
        builder: (context, chatSnapshot) {
          if (chatSnapshot.hasError) {
            return Center(
              child: Text('Error loading chat: ${chatSnapshot.error}'),
            );
          }

          if (!chatSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          
          final chatData = chatSnapshot.data?.data() as Map<String, dynamic>?;
          if (chatData == null) {
            return Center(child: Text('Chat not found'));
          }

          final chatStatus = chatData['status'] ?? 'active';
          
          if (chatStatus == 'completed') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('This chat has ended', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: _chatService.getMessages(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(height: 8),
                            Text('Error loading messages: ${snapshot.error}'),
                          ],
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data ?? [];
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(localizations.translate('no_messages')),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMyMessage = message.senderId == _userId;

                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            mainAxisAlignment: isMyMessage
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMyMessage
                                      ? AppTheme.primaryBlue
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMyMessage
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.senderName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isMyMessage
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      message.message,
                                      style: TextStyle(
                                        color: isMyMessage
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          DateFormat('HH:mm').format(message.timestamp),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isMyMessage
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                        ),
                                        if (isMyMessage) ...[
                                          SizedBox(width: 4),
                                          Icon(
                                            message.isRead ? Icons.done_all : Icons.done,
                                            size: 12,
                                            color: Colors.white70,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: localizations.translate('type_message'),
                    labelText: 'Message',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        if (_messageController.text.trim().isNotEmpty) {
                          _sendMessage(_messageController.text);
                          _messageController.clear();
                        }
                      },
                    ),
                  ),
                  maxLines: 3,
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      _sendMessage(text);
                      _messageController.clear();
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 