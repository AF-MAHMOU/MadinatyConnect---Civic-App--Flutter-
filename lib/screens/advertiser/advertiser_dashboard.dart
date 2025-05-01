import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../auth/login_screen.dart';

class AdvertiserDashboard extends StatefulWidget {
  @override
  _AdvertiserDashboardState createState() => _AdvertiserDashboardState();
}

class _AdvertiserDashboardState extends State<AdvertiserDashboard> {
  int _currentIndex = 0;
  List<Widget> _tabs = []; // Safe initialization

  final TextEditingController _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _adImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _tabs = [
            _buildSubmitAdTab(),
            _buildMyAdsTab(),
            _buildAnalyticsTab(),
            _buildProfileTab(),
          ];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Advertiser Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body:
          _tabs.isEmpty
              ? Center(child: CircularProgressIndicator())
              : _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'Submit Ad'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'My Ads'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildSubmitAdTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: 'Ad Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.upload),
            label: Text(_adImage == null ? 'Select Image' : 'Image Selected'),
            onPressed: () async {
              final image = await _picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 85,
              );
              setState(() => _adImage = image);
            },
          ),
          SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            onPressed: _submitAd,
            child: Text('Submit Advertisement'),
          ),
        ],
      ),
    );
  }

  Widget _buildMyAdsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('ads')
              .where(
                'advertiserId',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No ads submitted yet'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final ad = snapshot.data!.docs[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(ad['description']),
                subtitle: Text(
                  'Submitted: ${_formatDate(ad['timestamp'].toDate())}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: Chip(
                  label: Text(
                    ad['status'].toString().toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _getStatusColor(ad['status']),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final adsRef = FirebaseFirestore.instance.collection('ads');

      return FutureBuilder<QuerySnapshot>(
        future: adsRef.where('advertiserId', isEqualTo: uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          final total = docs.length;
          final approved =
              docs.where((doc) => doc['status'] == 'approved').length;
          final pending =
              docs.where((doc) => doc['status'] == 'pending').length;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ad Analytics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
                Text('Total Ads: $total'),
                Text('Approved Ads: $approved'),
                Text('Pending Ads: $pending'),
                if (total > 0)
                  Text(
                    'Approval Rate: ${(approved / total * 100).toStringAsFixed(1)}%',
                  ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      return Center(child: Text('Analytics loading failed: $e'));
    }
  }

  Widget _buildProfileTab() {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return Center(child: Text('User not authenticated'));
      }

      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advertiser Profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Text('Email: ${user.email}'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                FirebaseAuth.instance.sendPasswordResetEmail(
                  email: user.email!,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password reset link sent to ${user.email}'),
                  ),
                );
              },
              child: Text('Reset Password'),
            ),
          ],
        ),
      );
    } catch (e) {
      return Center(child: Text('Profile loading failed: $e'));
    }
  }

  Future<void> _submitAd() async {
    if (_descController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter ad description')));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('ads').add({
        'description': _descController.text,
        'advertiserId': FirebaseAuth.instance.currentUser!.uid,
        'status': 'pending',
        'timestamp': Timestamp.now(),
        'imageUrl': '',
      });

      _descController.clear();
      setState(() => _adImage = null);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ad submitted for approval')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting ad: $e')));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
