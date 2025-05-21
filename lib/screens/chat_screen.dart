import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';
import '../utils/app_theme.dart';
import '../utils/app_localizations.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import '../services/text_moderation_service.dart';


class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String otherUserId;

  const ChatScreen({
    required this.chatId,
    required this.otherUserName,
    required this.otherUserId,
    Key? key,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _chatService = ChatService();
  final _userId = FirebaseAuth.instance.currentUser?.uid;
  final _scrollController = ScrollController();
  bool _isAdmin = false;
  bool _isSending = false;
  String? _error;
  final Map<String, bool> _sendingMessages = {};
  final Map<String, Timer> _typingTimers = {};
  bool _isOtherTyping = false;
  bool _showScrollToBottom = false;
  bool _isUserTyping = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    _setupTypingListener();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels < 100) {
      if (_showScrollToBottom) {
        setState(() => _showScrollToBottom = false);
      }
    } else {
      if (!_showScrollToBottom) {
        setState(() => _showScrollToBottom = true);
      }
    }
  }

  Future<void> _initialize() async {
    try {
      await _checkUserRole();
      if (_userId != null) {
        await _chatService.markMessagesAsRead(widget.chatId, _userId!);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to initialize chat: $e');
      }
    }
  }

  Future<void> _checkUserRole() async {
    if (_userId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .get();
        if (mounted) {
          setState(() => _isAdmin = userDoc.data()?['role'] == 'admin');
        }
      } catch (e) {
        debugPrint('Error checking user role: $e');
      }
    }
  }

  void _setupTypingListener() {
    if (widget.chatId.isEmpty) return;
    
    FirebaseFirestore.instance.collection('chats')
      .doc(widget.chatId)
      .snapshots()
      .listen((snapshot) {
        if (!mounted) return;
        
        final data = snapshot.data();
        if (data != null) {
          final typingData = data['typing'] as Map<String, dynamic>? ?? {};
          final otherUserId = widget.otherUserId;
          
          if (typingData.containsKey(otherUserId) && typingData[otherUserId] == true) {
            if (!_isOtherTyping) {
              setState(() => _isOtherTyping = true);
            }
            // Clear any existing timer
            _typingTimers[otherUserId]?.cancel();
            // Set a new timer to hide typing indicator after 3 seconds
            _typingTimers[otherUserId] = Timer(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() => _isOtherTyping = false);
              }
            });
          }
        }
      });
  }

  void _updateTypingStatus(bool isTyping) {
    if (_userId == null || widget.chatId.isEmpty) return;
    
    FirebaseFirestore.instance.collection('chats')
      .doc(widget.chatId)
      .update({
        'typing': {
          _userId!: isTyping
        }
      });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    for (var timer in _typingTimers.values) {
      timer.cancel();
    }
    _updateTypingStatus(false);
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

     final isProfane = await TextModerationService.isProfane(text);
  if (isProfane) {
    // Show SnackBar for profanity instead of throwing exception
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your message contains inappropriate content. Please revise your message.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
    return; // Exit the function without sending the message
  }
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _isSending = true;
      _sendingMessages[messageId] = true;
    });
    
    final messageText = text.trim();
    _messageController.clear();
    _updateTypingStatus(false);

    try {
      await _chatService.sendMessage(widget.chatId, messageText);
      
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      _messageController.text = messageText;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('inappropriate content')
                ? 'Your message contains inappropriate content'
                : 'Failed to send message',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendingMessages.remove(messageId);
        });
      }
    }
  }

  String _extractMessageContent(String rawMessage) {
    try {
      if (rawMessage.startsWith('{') && rawMessage.endsWith('}')) {
        final jsonMap = json.decode(rawMessage) as Map<String, dynamic>;
        if (jsonMap.containsKey('result')) {
          return jsonMap['result'].toString();
        }
      }
      return rawMessage;
    } catch (e) {
      return rawMessage;
    }
  }

  Future<void> _endChat() async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({'status': 'completed'});
      
      await _chatService.updateChatRequestStatus(widget.chatId, 'completed');
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat ended successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to end chat: $e')),
      );
    }
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMyMessage) {
    final isSending = _sendingMessages.containsKey(message.id);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMyMessage 
                  ? (isSending ? Colors.grey[400] : AppTheme.primaryBlue) 
                  : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMyMessage ? 16 : 4),
                  bottomRight: Radius.circular(isMyMessage ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMyMessage)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  if (!isMyMessage) const SizedBox(height: 4),
                  Text(
                    _extractMessageContent(message.message),
                    style: TextStyle(
                      color: isMyMessage ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSending)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMyMessage ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      if (isMyMessage && !isSending) ...[
                        const SizedBox(width: 4),
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
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.otherUserName,
          style: const TextStyle(fontSize: 16),
        ),
        if (_isOtherTyping)
          Text(
            'typing...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green,
              fontStyle: FontStyle.italic,
            ),
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.otherUserName)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                  _initialize();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: _buildChatHeader(),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('End Chat'),
                  content: const Text('Are you sure you want to end this chat?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _endChat();
                      },
                      child: const Text('End Chat'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatId)
                      .snapshots(),
                  builder: (context, chatSnapshot) {
                    if (chatSnapshot.hasError) {
                      return Center(child: Text('Error loading chat: ${chatSnapshot.error}'));
                    }

                    final chatData = chatSnapshot.data?.data() as Map<String, dynamic>?;
                    if (chatData == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final chatStatus = chatData['status'] ?? 'active';
                    
                    if (chatStatus == 'completed') {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, size: 64, color: Colors.green),
                            const SizedBox(height: 16),
                            const Text('This chat has ended', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                      );
                    }

                    return StreamBuilder<List<ChatMessage>>(
                      stream: _chatService.getMessages(widget.chatId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red),
                                const SizedBox(height: 8),
                                Text('Error loading messages: ${snapshot.error}'),
                              ],
                            ),
                          );
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
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMyMessage = message.senderId == _userId;
                            return _buildMessageBubble(message, isMyMessage);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: localizations.translate('type_message'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.cardColor,
                        ),
                        maxLines: 3,
                        minLines: 1,
                        onChanged: (text) {
                          if (!_isUserTyping && text.isNotEmpty) {
                            setState(() => _isUserTyping = true);
                            _updateTypingStatus(true);
                          } else if (_isUserTyping && text.isEmpty) {
                            setState(() => _isUserTyping = false);
                            _updateTypingStatus(false);
                          }
                        },
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            _sendMessage(text);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryBlue,
                      ),
                      child: IconButton(
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white),
                        onPressed: _isSending
                            ? null
                            : () {
                                if (_messageController.text.trim().isNotEmpty) {
                                  _sendMessage(_messageController.text);
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showScrollToBottom)
            Positioned(
              bottom: 80,
              right: 20,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: AppTheme.primaryBlue,
                child: const Icon(Icons.arrow_downward, size: 20, color: Colors.white),
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}