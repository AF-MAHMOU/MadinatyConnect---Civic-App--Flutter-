import 'package:cloud_firestore/cloud_firestore.dart';

class IssueReport {
  final String id;
  final String userId;
  final String type;
  final String description;
  final String? imageUrl;
  final double lat;
  final double lng;
  final String status; // "pending", "resolved", etc.
  final DateTime submittedAt;

  IssueReport({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    this.imageUrl,
    required this.lat,
    required this.lng,
    required this.status,
    required this.submittedAt,
  });

  factory IssueReport.fromMap(Map<String, dynamic> map, String docId) {
    return IssueReport(
      id: docId,
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      lat: map['lat'],
      lng: map['lng'],
      status: map['status'] ?? 'pending',
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'description': description,
      'imageUrl': imageUrl,
      'lat': lat,
      'lng': lng,
      'status': status,
      'createdAt': Timestamp.fromDate(submittedAt), // Always use createdAt
      'timestamp': Timestamp.fromDate(submittedAt), // Keep for backward compatibility
    };
  }
}
