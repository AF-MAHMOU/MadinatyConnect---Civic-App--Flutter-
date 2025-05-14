import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PollCard extends StatefulWidget {
  final String question;
  final List<String> options;
  final String pollId;

  PollCard({
    required this.question,
    required this.options,
    required this.pollId,
  });

  @override
  _PollCardState createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  Future<void> _vote(String option) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final pollRef = FirebaseFirestore.instance
          .collection('polls')
          .doc(widget.pollId)
          .collection('votes')
          .doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(pollRef, {'option': option});
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Vote submitted!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting vote: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.question,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...widget.options.map(
              (option) => ElevatedButton(
                onPressed: () => _vote(option),
                child: Text(option),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 40),
                ),
              ),
            ),
            SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('polls')
                      .doc(widget.pollId)
                      .collection('votes')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return LinearProgressIndicator();

                final totalVotes = snapshot.data!.docs.length;
                final votesMap = <String, int>{};

                for (var doc in snapshot.data!.docs) {
                  final option = doc['option'];
                  votesMap[option] = (votesMap[option] ?? 0) + 1;
                }

                return Column(
                  children:
                      votesMap.entries
                          .map(
                            (entry) => PollResultRow(
                              option: entry.key,
                              count: entry.value,
                              total: totalVotes,
                            ),
                          )
                          .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PollResultRow extends StatelessWidget {
  final String option;
  final int count;
  final int total;

  PollResultRow({
    required this.option,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(option)),
          Expanded(
            flex: 5,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          SizedBox(width: 8),
          Text('${(percentage * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}
