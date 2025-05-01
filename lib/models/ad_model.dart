import 'package:cloud_firestore/cloud_firestore.dart';

class Ad {
  final String id;
  final String advertiserId;
  final String title;
  final String description;
  final String mediaUrl;
  final bool approved;
  final DateTime submittedAt;

  Ad({
    required this.id,
    required this.advertiserId,
    required this.title,
    required this.description,
    required this.mediaUrl,
    required this.approved,
    required this.submittedAt,
  });

  factory Ad.fromMap(Map<String, dynamic> map, String docId) {
    return Ad(
      id: docId,
      advertiserId: map['advertiserId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      approved: map['approved'] ?? false,
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'advertiserId': advertiserId,
      'title': title,
      'description': description,
      'mediaUrl': mediaUrl,
      'approved': approved,
      'submittedAt': submittedAt,
    };
  }
}
