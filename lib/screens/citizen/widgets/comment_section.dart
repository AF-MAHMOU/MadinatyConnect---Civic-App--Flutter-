import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../utils/app_localizations.dart';
import '../../../services/text_moderation_service.dart';

class CommentSection extends StatefulWidget {
  final String announcementId;

  CommentSection({required this.announcementId});

  @override
  _CommentSectionState createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  bool _isAnonymous = true;
  bool _isExpanded = false;
  String? _userName;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (mounted) {
        setState(() {
          _userName = userDoc.data()?['name'] ?? 'Anonymous';
        });
      }
    }
  }

  Future<void> _addComment(String text) async {
    if (text.trim().isEmpty) return;
    final localizations = AppLocalizations.of(context);

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Check for profanity
      final isProfane = await TextModerationService.isProfane(text);
      if (isProfane) {
        throw Exception('Your comment contains inappropriate content. Please revise your comment.');
      }

      // Filter profanity from the comment
      final filteredText = await TextModerationService.filterProfanity(text);

      await FirebaseFirestore.instance
          .collection('announcements/${widget.announcementId}/comments')
          .add({
        'text': filteredText,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'name': _isAnonymous ? 'Anonymous' : _userName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comment posted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Failed to post comment';
      if (e.toString().contains('inappropriate content')) {
        errorMessage = 'Your comment contains inappropriate content. Please revise your comment.';
      }
      
      if (mounted) {
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
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            localizations.translate('comments'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          trailing: IconButton(
            icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
        ),
        if (_isExpanded) ...[
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('announcements/${widget.announcementId}/comments')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                    '${localizations.translate('error_loading_comments')}: ${snapshot.error}');
              }

              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final comments = snapshot.data!.docs;

              if (comments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(localizations.translate('no_comments')),
                );
              }

              return Column(
                children: comments.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(data['text'] ?? 'No text'),
                      subtitle: Text(data['name'] ?? 'Anonymous'),
                      trailing: Text(
                        data['timestamp'] != null
                            ? DateFormat('MMM dd, HH:mm').format(
                                (data['timestamp'] as Timestamp).toDate())
                            : '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: localizations.translate('add_comment'),
                labelText: 'Comment',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                          if (_commentController.text.trim().isNotEmpty) {
                            _addComment(_commentController.text);
                          }
                        },
                      ),
              ),
              maxLines: 3,
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  _addComment(text);
                }
              },
            ),
          ),
          Row(
            children: [
              Checkbox(
                value: _isAnonymous,
                onChanged: (value) {
                  setState(() {
                    _isAnonymous = value ?? true;
                  });
                },
              ),
              Text(localizations.translate('post_anonymously')),
            ],
          ),
        ]
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
