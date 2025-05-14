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

class _PollsTab extends StatefulWidget {
  @override
  _PollsTabState createState() => _PollsTabState();
}

class _PollsTabState extends State<_PollsTab> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  final List<String> _options = [];

  @override
  void initState() {
    super.initState();
    _addNewOptionField();  // Start with one option field.
  }

  // Function to add a new option field
  void _addNewOptionField() {
    final optionController = TextEditingController();
    _optionControllers.add(optionController);
    setState(() {});
  }

  // Function to remove an option field
  void _removeOptionField(int index) {
    _optionControllers.removeAt(index);
    setState(() {});
  }

  // Function to submit the poll
  void _submitPoll() async {
    if (_questionController.text.isEmpty || _options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please provide a question and at least one option')));
      return;
    }

    // Prepare the poll data
    final pollData = {
      'question': _questionController.text,
      'options': _options,
      'endDate': Timestamp.fromDate(
        DateTime.now().add(Duration(days: 7)), // Poll expires in 7 days
      ),
    };

    try {
      // Add the poll to Firestore
      await FirebaseFirestore.instance.collection('polls').add(pollData);

      // Clear the form
      _questionController.clear();
      _optionControllers.clear();
      _options.clear();
      _addNewOptionField();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Poll created successfully'),
        backgroundColor: Colors.green, // Optional: Make it green for success
      ));
    } catch (e) {
      // Handle errors and show an error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to create poll: $e'),
        backgroundColor: Colors.red, // Optional: Make it red for errors
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Question input field
          TextField(
            controller: _questionController,
            decoration: InputDecoration(labelText: 'Question'),
          ),
          SizedBox(height: 10),
          
          // Dynamic option input fields
          Column(
            children: _optionControllers.map((controller) {
              int index = _optionControllers.indexOf(controller);
              return Row(
                children: [
                  // Option input field
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(labelText: 'Option ${index + 1}'),
                      onChanged: (value) {
                        // Update the options list as the user types
                        if (value.isEmpty) {
                          _options.removeAt(index);
                        } else {
                          if (index >= _options.length) {
                            _options.add(value);
                          } else {
                            _options[index] = value;
                          }
                        }
                      },
                    ),
                  ),
                  // Remove option button
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () => _removeOptionField(index),
                  ),
                ],
              );
            }).toList(),
          ),
          
          SizedBox(height: 10),
          
          // Button to add new option field
          ElevatedButton(
            onPressed: _addNewOptionField,
            child: Text('Add Option'),
          ),
          
          SizedBox(height: 10),
          
          // Button to submit the poll
          ElevatedButton(
            onPressed: _submitPoll,
            child: Text('Create Poll'),
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
