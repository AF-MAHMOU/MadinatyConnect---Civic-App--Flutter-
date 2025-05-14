import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/poll_card.dart';
import '../../utils/dark_mode_helper.dart';

class PollScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return DarkModeHelper.addDarkModeToggle(
      Scaffold(
        appBar: AppBar(title: Text('Polls')),
        body: StreamBuilder<QuerySnapshot>(
          stream:
              _firestore
                  .collection('polls')
                  .where('endDate', isGreaterThan: Timestamp.now())
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return Center(child: CircularProgressIndicator());

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var poll = snapshot.data!.docs[index];
                return PollCard(
                  question: poll['question'],
                  options: List<String>.from(poll['options']),
                  pollId: poll.id,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
