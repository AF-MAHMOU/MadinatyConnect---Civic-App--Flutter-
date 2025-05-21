import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/announcment_card.dart';
import 'widgets/ad_card.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Madinaty Connect'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Sponsored Ads Section
          Text(
            '💰 Sponsored Ads',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('ads')
                .where('status', isEqualTo: "approved")
                .snapshots(),
            builder: (context, adSnapshot) {
              if (adSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (adSnapshot.hasError) {
                return Text('Error loading ads: ${adSnapshot.error}');
              } else if (!adSnapshot.hasData ||
                  adSnapshot.data!.docs.isEmpty) {
                return const Text('No sponsored ads at the moment.');
              }

              return Column(
                children: adSnapshot.data!.docs.map((doc) {
                  final adData = doc.data() as Map<String, dynamic>;
                  return AdCard(
                    description: adData['description'] ?? '',
                    imageUrl: adData['imageUrl'] ?? '',
                    timestamp: (adData['timestamp'] as Timestamp).toDate(),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // Announcements Section
          Text(
            '📣 Announcements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('announcements')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text(
                    'Error loading announcements: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('No announcements available.');
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  return AnnouncementCard(
                    id: doc.id,
                    title: doc['title'],
                    content: doc['description'],
                    date: (doc['date'] as Timestamp).toDate(),
                    attachments:
                        (doc.data() as Map<String, dynamic>?)
                                    ?.containsKey('attachments') ==
                                true
                            ? doc['attachments']
                            : [],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
