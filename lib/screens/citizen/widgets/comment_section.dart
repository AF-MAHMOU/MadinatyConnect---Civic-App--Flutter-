import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentSection extends StatelessWidget {
  final String announcementId;

  CommentSection({required this.announcementId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('announcements/$announcementId/comments')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        return Column(
          children:
              snapshot.data!.docs
                  .map((doc) => ListTile(title: Text(doc['text'])))
                  .toList(),
        );
      },
    );
  }
}
