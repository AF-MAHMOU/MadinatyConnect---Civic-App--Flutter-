import 'package:cloud_firestore/cloud_firestore.dart';

class Poll {
  final String id;
  final String question;
  final List<String> options;
  final Map<String, int> votes; // option -> count
  final List<String> votedUserIds; // to prevent multiple votes
  final DateTime createdAt;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
    required this.votedUserIds,
    required this.createdAt,
  });

  factory Poll.fromMap(Map<String, dynamic> map, String docId) {
    return Poll(
      id: docId,
      question: map['question'] ?? '',
      options: List<String>.from(map['options']),
      votes: Map<String, int>.from(map['votes']),
      votedUserIds: List<String>.from(map['votedUserIds']),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'votes': votes,
      'votedUserIds': votedUserIds,
      'createdAt': createdAt,
    };
  }
}
