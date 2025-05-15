import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentTab = 0;
  final List<Widget> _tabs = [
    _AnnouncementsTab(),
    _PollsTab(),  // Add the PollsTab here
    _AdsApprovalTab(),
    _IssuesTab(),
    _UserManagementTab(), // New tab
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
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
    );
  }
}


class _AnnouncementsTab extends StatefulWidget {
  @override
  State<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String? _editingDocId;

  void _startEdit(DocumentSnapshot doc) {
    _editingDocId = doc.id;
    _titleController.text = doc['title'];
    _contentController.text = doc['description'];
    setState(() {});
  }

  void _cancelEdit() {
    _editingDocId = null;
    _titleController.clear();
    _contentController.clear();
    setState(() {});
  }

  Future<void> _saveAnnouncement() async {
    final data = {
      'title': _titleController.text.trim(),
      'description': _contentController.text.trim(),
      'date': Timestamp.now(),
    };

    if (_editingDocId != null) {
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(_editingDocId)
          .update(data);
    } else {
      await FirebaseFirestore.instance.collection('announcements').add(data);
    }

    _cancelEdit();
  }

  Future<void> _deleteAnnouncement(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Announcement'),
        content: Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('announcements').doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            _editingDocId != null ? 'Edit Announcement' : 'Post New Announcement',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 8),
          TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Title')),
          SizedBox(height: 8),
          TextField(controller: _contentController, decoration: InputDecoration(labelText: 'Content')),
          SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: _saveAnnouncement,
                child: Text(_editingDocId != null ? 'Update' : 'Post'),
              ),
              if (_editingDocId != null)
                TextButton(onPressed: _cancelEdit, child: Text('Cancel')),
            ],
          ),
          Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('announcements').orderBy('date', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(doc['title']),
                        subtitle: Text(doc['description']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: Icon(Icons.edit), onPressed: () => _startEdit(doc)),
                            IconButton(icon: Icon(Icons.delete), onPressed: () => _deleteAnnouncement(doc.id)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class _PollsTab extends StatefulWidget {
  @override
  _PollsTabState createState() => _PollsTabState();
}

class _PollsTabState extends State<_PollsTab> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  final List<String> _options = [];
  String? _editingPollId;

  @override
  void initState() {
    super.initState();
    _addNewOptionField();
  }

  void _addNewOptionField([String? value]) {
    final controller = TextEditingController(text: value);
    _optionControllers.add(controller);
    if (value != null) _options.add(value);
    setState(() {});
  }

  void _removeOptionField(int index) {
    _optionControllers.removeAt(index);
    if (index < _options.length) _options.removeAt(index);
    setState(() {});
  }

  void _startEditPoll(DocumentSnapshot doc) {
    _editingPollId = doc.id;
    _questionController.text = doc['question'];
    _options.clear();
    _optionControllers.clear();

    for (var option in List<String>.from(doc['options'])) {
      _addNewOptionField(option);
    }

    setState(() {});
  }

  void _cancelEditPoll() {
    _editingPollId = null;
    _questionController.clear();
    _optionControllers.clear();
    _options.clear();
    _addNewOptionField();
    setState(() {});
  }

  Future<void> _submitPoll() async {
    final question = _questionController.text.trim();
    _options.clear();
    for (var c in _optionControllers) {
      if (c.text.trim().isNotEmpty) _options.add(c.text.trim());
    }

    if (question.isEmpty || _options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter a question and at least two options.')));
      return;
    }

    final pollData = {
      'question': question,
      'options': _options,
      'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 7))),
    };

    if (_editingPollId != null) {
      await FirebaseFirestore.instance.collection('polls').doc(_editingPollId).update(pollData);
    } else {
      await FirebaseFirestore.instance.collection('polls').add(pollData);
    }

    _cancelEditPoll();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Poll saved successfully')));
  }

  Future<void> _deletePoll(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Poll'),
        content: Text('Are you sure you want to delete this poll?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('polls').doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            _editingPollId != null ? 'Edit Poll' : 'Create New Poll',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          TextField(controller: _questionController, decoration: InputDecoration(labelText: 'Question')),
          SizedBox(height: 8),
          Column(
            children: _optionControllers.map((controller) {
              int index = _optionControllers.indexOf(controller);
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(labelText: 'Option ${index + 1}'),
                    ),
                  ),
                  IconButton(icon: Icon(Icons.remove), onPressed: () => _removeOptionField(index)),
                ],
              );
            }).toList(),
          ),
          Row(
            children: [
              ElevatedButton(onPressed: _addNewOptionField, child: Text('Add Option')),
              SizedBox(width: 12),
              ElevatedButton(onPressed: _submitPoll, child: Text(_editingPollId != null ? 'Update' : 'Create Poll')),
              if (_editingPollId != null)
                TextButton(onPressed: _cancelEditPoll, child: Text('Cancel')),
            ],
          ),
          Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('polls').orderBy('endDate').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(doc['question']),
                        subtitle: Text('Options: ${List<String>.from(doc['options']).join(', ')}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: Icon(Icons.edit), onPressed: () => _startEditPoll(doc)),
                            IconButton(icon: Icon(Icons.delete), onPressed: () => _deletePoll(doc.id)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
