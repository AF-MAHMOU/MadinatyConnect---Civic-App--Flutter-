import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addIssue(Map<String, dynamic> issueData) async {
    await _firestore.collection('issues').add(issueData);
  }

  Stream<QuerySnapshot> getAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Add more methods like getPolls(), voteOnPoll(), etc.
}
