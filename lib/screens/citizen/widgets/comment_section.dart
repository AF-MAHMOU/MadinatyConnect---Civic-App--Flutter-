import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_localizations.dart';

class CommentSection extends StatefulWidget {
  final String announcementId;

  const CommentSection({required this.announcementId, Key? key}) : super(key: key);

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _controller = TextEditingController();
  bool _isAnonymous = false;
  bool _canSend = false;
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();

  final List<String> _offensiveWords = [
    'fuck you', 'fuck u', 'shit', 'damn', 'fuck', 'dumb' ,'dumbass'
    'كريه', 'غبي', 'قذر',
  ];

  @override
  void initState() {  
    super.initState();
    _controller.addListener(() {
      final isNotEmpty = _controller.text.trim().isNotEmpty;
      if (isNotEmpty != _canSend) {
        setState(() {
          _canSend = isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _containsOffensiveWords(String text) {
    final lowerText = text.toLowerCase();
    return _offensiveWords.any((word) => lowerText.contains(word));
  }

  Future<void> _postComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    if (_containsOffensiveWords(content)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Offensive language detected. Please revise.')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('announcements')
        .doc(widget.announcementId)
        .collection('comments')
        .add({
      'content': content,
      'isAnonymous': _isAnonymous,
      'createdAt': Timestamp.now(),
    });

    _controller.clear();

    await Future.delayed(Duration(milliseconds: 300));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final content = comment['content'] as String;
    final isAnon = comment['isAnonymous'] as bool? ?? true;
    final Timestamp ts = comment['createdAt'] as Timestamp;
    final dateTime = ts.toDate();
    final timeString = timeago.format(dateTime);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: Text(content),
        subtitle: Text(
          '${isAnon ? 'Anonymous' : 'User'} · $timeString',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ),
    );
  }

  @override
  _CommentSectionState createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final localizations = AppLocalizations.of(context);

    try {
      await FirebaseFirestore.instance
          .collection('announcements/${widget.announcementId}/comments')
          .add({
        'text': _commentController.text.trim(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.translate('error_loading_comments')}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return ExpansionTile(
      title: Text('Comments'),
      initiallyExpanded: _isExpanded,
      onExpansionChanged: (expanded) {
        setState(() {
          _isExpanded = expanded;
        });
      },
      children: [
        SizedBox(
          height: 250,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('announcements')
                .doc(widget.announcementId)
                .collection('comments')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No comments yet.'));
              }
              final comments = snapshot.data!.docs;
              return ListView.builder(
                controller: _scrollController,
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final commentData = comments[index].data()! as Map<String, dynamic>;
                  return _buildCommentItem(commentData);
                },
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                minLines: 1,
                maxLines: 3,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  FilterChip(
                    label: Text('Post anonymously'),
                    selected: _isAnonymous,
                    onSelected: (val) {
                      setState(() {
                        _isAnonymous = val;
                      });
                    },
                    selectedColor: Colors.blue[100],
                  ),
                  Spacer(),
                  ElevatedButton.icon(
                    onPressed: _canSend ? _postComment : null,
                    icon: Icon(Icons.send),
                    label: Text('Send'),
                  ),
                ],

    final localizations = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            localizations.translate('comments'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('announcements/${widget.announcementId}/comments')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('${localizations.translate('error_loading_comments')}: ${snapshot.error}');
            }

            if (!snapshot.hasData) {
              return CircularProgressIndicator();
            }

            final comments = snapshot.data!.docs;
            
            if (comments.isEmpty) {
              return Text(localizations.translate('no_comments'));
            }

            return Column(
              children: comments.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(data['text'] ?? 'No text'),
                  subtitle: Text(data['userId'] ?? 'Anonymous'),
                );
              }).toList(),
            );
          },
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: localizations.translate('add_comment'),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: _addComment,

              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
