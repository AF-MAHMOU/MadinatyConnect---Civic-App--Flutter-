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
        title: Text('Madinaty Connect'),
      ),
      body: ListView(
        padding: EdgeInsets.all(12),
        children: [
          // Sponsored Ads Section
          Text(
            '💰 Sponsored Ads',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('ads')
                .where('status', isEqualTo: "approved")
                .snapshots(),
            builder: (context, adSnapshot) {
              if (adSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (adSnapshot.hasError) {
                return Text('Error loading ads: ${adSnapshot.error}');
              } else if (!adSnapshot.hasData || adSnapshot.data!.docs.isEmpty) {
                return Text('No sponsored ads at the moment.');
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

          SizedBox(height: 24),

          
          Text(
            '📣 Announcements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('announcements')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, announcementSnapshot) {
              if (announcementSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (announcementSnapshot.hasError) {
                return Text('Error loading announcements: ${announcementSnapshot.error}');
              } else if (!announcementSnapshot.hasData || announcementSnapshot.data!.docs.isEmpty) {
                return Text('No announcements available.');
              }

              return Column(
                children: announcementSnapshot.data!.docs.map((doc) {
                  return AnnouncementCard(
                    id: doc.id,
                    title: doc['title'],
                    content: doc['description'],
                    date: (doc['date'] as Timestamp).toDate(),
                    attachments: (doc.data() as Map<String, dynamic>?)?.containsKey('attachments') == true? doc['attachments']: [],

                  );
                }).toList(),
              );
            },
          ),
        ],

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
    );
  }
}
