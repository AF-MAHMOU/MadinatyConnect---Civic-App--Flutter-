import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_localizations.dart';

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

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final localizations = AppLocalizations.of(context);

    try {
      await FirebaseFirestore.instance
          .collection('announcements/${widget.announcementId}/comments')
          .add({
        'text': _commentController.text.trim(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'name': _isAnonymous ? 'Anonymous' : _userName,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${localizations.translate('error_loading_comments')}: $e')),
      );
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
                .collection(
                    'announcements/${widget.announcementId}/comments')
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
                  return ListTile(
                    title: Text(data['text'] ?? 'No text'),
                    subtitle: Text(data['name'] ?? 'Anonymous'),
                  );
                }).toList(),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
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
