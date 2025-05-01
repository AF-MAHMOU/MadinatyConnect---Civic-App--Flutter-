import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? pdfUrl;
  final DateTime createdAt;
  final String postedBy; // user ID or "government"

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.pdfUrl,
    required this.createdAt,
    required this.postedBy,
  });

  factory Announcement.fromMap(Map<String, dynamic> map, String docId) {
    return Announcement(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      pdfUrl: map['pdfUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      postedBy: map['postedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'pdfUrl': pdfUrl,
      'createdAt': createdAt,
      'postedBy': postedBy,
    };
  }
}
