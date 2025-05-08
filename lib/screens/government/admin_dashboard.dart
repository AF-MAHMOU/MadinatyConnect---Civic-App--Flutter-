import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import '../../utils/dark_mode_helper.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentTab = 0;
  final List<Widget> _tabs = [
    _AnnouncementsTab(),
    _PollsTab(),
    _AdsApprovalTab(),
    _IssuesTab(),
    _UserManagementTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return DarkModeHelper.addDarkModeToggle(
      Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
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
        body: _tabs[_currentTab],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (index) => setState(() => _currentTab = index),
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.announcement),
              label: 'Announcements',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.poll), label: 'Polls'),
            BottomNavigationBarItem(icon: Icon(Icons.ad_units), label: 'Ads'),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem),
              label: 'Issues',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts),
              label: 'Users',
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementsTab extends StatelessWidget {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: _contentController,
            decoration: InputDecoration(labelText: 'Content'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('announcements').add({
                'title': _titleController.text,
                'description': _contentController.text,
                'date': Timestamp.now(),
              });
            },
            child: Text('Post Announcement'),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('announcements')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(doc['title']),
                      subtitle: Text(doc['description']),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PollsTab extends StatelessWidget {
  final TextEditingController _questionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _questionController,
            decoration: InputDecoration(labelText: 'Question'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('polls').add({
                'question': _questionController.text,
                'options': ['Yes', 'No'],
                'endDate': Timestamp.fromDate(
                  DateTime.now().add(Duration(days: 7)),
                ),
              });
            },
            child: Text('Create Poll'),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('polls').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var poll = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(poll['question']),
                      subtitle: Text('Options: ${poll['options'].join(', ')}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdsApprovalTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('ads')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var ad = snapshot.data!.docs[index];
            return ListTile(
              title: Text(ad['description']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check),
                    onPressed:
                        () => ad.reference.update({'status': 'approved'}),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed:
                        () => ad.reference.update({'status': 'rejected'}),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _IssuesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('issues').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var issue = snapshot.data!.docs[index];
            return ListTile(
              title: Text(issue['description']),
              subtitle: Text('Status: ${issue['status']}'),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _updateStatus(context, issue.reference),
              ),
            );
          },
        );
      },
    );
  }

  void _updateStatus(BuildContext context, DocumentReference ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Update Status'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return DropdownButton<String>(
                  value: 'reported',
                  items:
                      ['reported', 'in progress', 'resolved']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.update({'status': value});
                      Navigator.pop(context);
                    }
                  },
                );
              },
            ),
          ),
    );
  }
}

class _UserManagementTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var userDoc = snapshot.data!.docs[index];
            var email = userDoc['email'];
            var role = userDoc['role'];
            var uid = userDoc.id;

            return ListTile(
              title: Text(email),
              subtitle: Text('Role: $role'),
              trailing: DropdownButton<String>(
                value: role,
                items:
                    ['citizen', 'advertiser', 'admin']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                onChanged: (newRole) {
                  if (newRole != null && newRole != role) {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({'role': newRole});
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
