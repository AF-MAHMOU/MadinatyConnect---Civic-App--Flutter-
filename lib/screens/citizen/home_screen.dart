import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/announcment_card.dart';
import '../../utils/dark_mode_helper.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return DarkModeHelper.addDarkModeToggle(
      Scaffold(
        appBar: AppBar(title: const Text('Announcements')),
        body: StreamBuilder<QuerySnapshot>(
          stream:
              _firestore
                  .collection('announcements')
                  .orderBy('date', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error loading announcements: ${snapshot.error}'),
              );
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No announcements available.'));
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var announcement = snapshot.data!.docs[index];
                return AnnouncementCard(
                  title: announcement['title'],
                  content: announcement['description'],
                  date: (announcement['date'] as Timestamp).toDate(),
                  attachments:
                      (announcement.data() as Map<String, dynamic>?)
                                  ?.containsKey('attachments') ==
                              true
                          ? announcement['attachments']
                          : [],
                  id: announcement.id,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
