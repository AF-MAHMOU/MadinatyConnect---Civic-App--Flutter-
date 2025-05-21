import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';
import 'admin_chat_requests.dart';
import '../../utils/app_localizations.dart';
import '../../main.dart';
import '../chat_screen.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentTab = 0;
  bool _isLoading = false;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _OverviewTab(),
      _AnnouncementsTab(),
      _PollsTab(),
      _AdsApprovalTab(),
      _IssuesTab(),
      _UserManagementTab(),
    ];
  }

  String _getAppBarTitle() {
    switch (_currentTab) {
      case 0:
        return 'Overview';
      case 1:
        return 'Announcements';
      case 2:
        return 'Polls';
      case 3:
        return 'Ads';
      case 4:
        return 'Issues';
      case 5:
        return 'Users';
      default:
        return 'Admin Dashboard';
    }
  }

  void _showChatRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminChatRequests()),
    );
  }

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Logout', style: AppTheme.titleLarge),
        content: Text(
          'Are you sure you want to logout from the admin dashboard?',
          style: AppTheme.bodyLarge,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTheme.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                await AuthService().logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error logging out: $e'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
              setState(() => _isLoading = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chat_requests')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              int pendingCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
              
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.chat),
                    onPressed: _showChatRequests,
                    tooltip: localizations.translate('chat_requests'),
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          pendingCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.announcement),
            label: 'Announcements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.poll),
            label: 'Polls',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.ad_units),
            label: 'Ads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Issues',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: 'Users',
          ),
        ],
        onTap: (index) {
          if (index >= 0 && index < _screens.length) {
            setState(() => _currentTab = index);
          }
        },
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Active Chats'),
          _buildActiveChats(),
          SizedBox(height: 24),
          _buildSectionTitle(context, 'Recent Announcements'),
          _buildRecentAnnouncements(),
          SizedBox(height: 24),
          _buildSectionTitle(context, 'Active Polls'),
          _buildActivePolls(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActiveChats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('status', isEqualTo: 'active')
          .orderBy('lastMessageTime', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final chats = snapshot.data?.docs ?? [];
        if (chats.isEmpty) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('No active chats'),
              ),
            ),
          );
        }

        return Column(
          children: chats.map((chat) {
            final data = chat.data() as Map<String, dynamic>;
            final lastMessage = data['lastMessage'] ?? 'No messages';
            final lastMessageTime = data['lastMessageTime'] as Timestamp?;
            final citizenId = data['citizenId'] ?? '';

            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue,
                  child: Icon(Icons.chat, color: Colors.white),
                ),
                title: StreamBuilder<DocumentSnapshot>(
                  stream: citizenId.isNotEmpty
                      ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(citizenId)
                          .snapshots()
                      : null,
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData || citizenId.isEmpty) {
                      return Text('Unknown User');
                    }
                    final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                    return Text(userData?['name'] ?? 'Unknown User');
                  },
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      lastMessageTime != null
                          ? DateFormat('MMM dd, HH:mm').format(lastMessageTime.toDate())
                          : 'No time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chat.id,
                        otherUserName: 'Citizen',
                        otherUserId: citizenId,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRecentAnnouncements() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('date', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final announcements = snapshot.data?.docs ?? [];
        if (announcements.isEmpty) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('No announcements'),
              ),
            ),
          );
        }

        return Column(
          children: announcements.map((announcement) {
            final data = announcement.data() as Map<String, dynamic>;
            final timestamp = data['date'] as Timestamp?;

            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue,
                  child: Icon(Icons.announcement, color: Colors.white),
                ),
                title: Text(
                  data['title'] ?? 'No title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['description'] ?? 'No content',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      timestamp != null
                          ? DateFormat('MMM dd, yyyy').format(timestamp.toDate())
                          : 'No date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActivePolls() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('polls')
          .where('endDate', isGreaterThan: Timestamp.now())
          .orderBy('endDate')
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final polls = snapshot.data?.docs ?? [];
        if (polls.isEmpty) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('No active polls'),
              ),
            ),
          );
        }

        return Column(
          children: polls.map((poll) {
            final data = poll.data() as Map<String, dynamic>;
            final options = List<String>.from(data['options'] ?? []);
            final endDate = (data['endDate'] as Timestamp).toDate();
            
            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.poll, color: AppTheme.primaryBlue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['question'] ?? 'No question',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Ends on ${DateFormat('MMM dd, yyyy').format(endDate)}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ...options.map((option) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('polls')
                            .doc(poll.id)
                            .collection('votes')
                            .where('option', isEqualTo: option)
                            .snapshots(),
                        builder: (context, votesSnapshot) {
                          final votes = votesSnapshot.data?.docs.length ?? 0;
                          return Row(
                            children: [
                              Expanded(child: Text(option)),
                              Text('$votes votes'),
                            ],
                          );
                        },
                      ),
                    )),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _AnnouncementsTab extends StatefulWidget {
  @override
  _AnnouncementsTabState createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isEditing = false;
  String? _editingId;
  bool _isCreateExpanded = false;

  void _clearForm() {
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _isEditing = false;
      _editingId = null;
      _isCreateExpanded = false;
    });
  }

  void _editAnnouncement(DocumentSnapshot doc) {
    _titleController.text = doc['title'];
    _contentController.text = doc['description'];
    setState(() {
      _isEditing = true;
      _editingId = doc.id;
      _isCreateExpanded = true;
    });
  }

  Future<void> _deleteAnnouncement(String id) async {
    try {
      await FirebaseFirestore.instance.collection('announcements').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Announcement deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting announcement: $e')),
      );
    }
  }

  Future<void> _saveAnnouncement() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in both title and content')),
      );
      return;
    }

    try {
      final data = {
        'title': _titleController.text.trim(),
        'description': _contentController.text.trim(),
        'date': Timestamp.now(),
        'postedBy': 'government',
      };

      if (_isEditing && _editingId != null) {
        await FirebaseFirestore.instance
            .collection('announcements')
            .doc(_editingId)
            .update(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Announcement updated successfully')),
        );
      } else {
        await FirebaseFirestore.instance.collection('announcements').add(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Announcement posted successfully')),
        );
      }
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving announcement: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                _isEditing ? 'Edit Announcement' : 'Create Announcement',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: Icon(
                _isEditing ? Icons.edit : Icons.add_circle_outline,
                color: AppTheme.primaryBlue,
              ),
              initiallyExpanded: _isCreateExpanded,
              onExpansionChanged: (expanded) {
                if (!expanded) _clearForm();
              },
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          hintText: 'Enter a clear, concise title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.title),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _contentController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Content',
                          hintText: 'Enter the announcement details...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: _clearForm,
                            icon: Icon(Icons.clear),
                            label: Text('Clear'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _saveAnnouncement,
                            icon: Icon(_isEditing ? Icons.save : Icons.send),
                            label: Text(_isEditing ? 'Update' : 'Post'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Recent Announcements',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.announcement_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No announcements yet',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var date = (doc['date'] as Timestamp).toDate();

                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                          child: Icon(
                            Icons.announcement,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        title: Text(
                          doc['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 8),
                            Text(
                              doc['description'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Posted on ${DateFormat('MMM dd, yyyy').format(date)}',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: AppTheme.primaryBlue),
                              onPressed: () => _editAnnouncement(doc),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Delete Announcement'),
                                  content: Text('Are you sure you want to delete this announcement?'),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteAnnouncement(doc.id);
                                      },
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(doc['title']),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(doc['description']),
                                  SizedBox(height: 16),
                                  Text(
                                    'Posted on ${DateFormat('MMM dd, yyyy').format(date)}',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Close'),
                              ),
                            ],
                          ),
                        ),
                      ),
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
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _isCreateExpanded = false;
  bool _isEditing = false;
  String? _editingId;
  List<DocumentSnapshot> votes = [];
  Map<String, List<String>> votesByOption = {};

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  void _clearForm() {
    _questionController.clear();
    for (var controller in _optionControllers) {
      controller.clear();
    }
    setState(() {
      _isEditing = false;
      _editingId = null;
      _isCreateExpanded = false;
    });
  }

  void _editPoll(DocumentSnapshot poll) {
    _questionController.text = poll['question'];
    // Clear existing controllers
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    _optionControllers.clear();
    // Add controllers for existing options
    for (var option in poll['options']) {
      var controller = TextEditingController(text: option);
      _optionControllers.add(controller);
    }
    setState(() {
      _isEditing = true;
      _editingId = poll.id;
      _isCreateExpanded = true;
    });
  }

  Future<void> _deletePoll(String id) async {
    try {
      await FirebaseFirestore.instance.collection('polls').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Poll deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting poll: $e')),
      );
    }
  }

  Future<void> _savePoll() async {
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a question')),
      );
      return;
    }

    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least 2 options')),
      );
      return;
    }

    try {
      final data = {
        'question': _questionController.text.trim(),
        'options': options,
        'endDate': Timestamp.fromDate(
          DateTime.now().add(Duration(days: 7)),
        ),
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_isEditing && _editingId != null) {
        await FirebaseFirestore.instance
            .collection('polls')
            .doc(_editingId)
            .update(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Poll updated successfully')),
        );
      } else {
        await FirebaseFirestore.instance.collection('polls').add(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Poll created successfully')),
        );
      }

      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving poll: $e')),
      );
    }
  }

  void _showPollDetails(DocumentSnapshot poll) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('polls')
                .doc(poll.id)
                .collection('votes')
                .snapshots(),
            builder: (context, votesSnapshot) {
              if (!votesSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              votes = votesSnapshot.data!.docs;
              votesByOption = {};
              
              // Initialize options
              for (var option in poll['options']) {
                votesByOption[option] = [];
              }

              // Group voters by option
              for (var vote in votes) {
                final option = vote['option'];
                final userEmail = vote['userEmail'] ?? 'Anonymous';
                votesByOption[option]?.add(userEmail);
              }

              return SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            poll['question'],
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Total Votes: ${votes.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ...votesByOption.entries.map((entry) {
                      final percentage = votes.isEmpty
                          ? 0.0
                          : (entry.value.length / votes.length) * 100;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '${entry.value.length} votes (${percentage.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: AppTheme.lightGrey,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryBlue,
                              ),
                              minHeight: 8,
                            ),
                          ),
                          if (entry.value.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: entry.value.map((voter) {
                                return Chip(
                                  label: Text(
                                    voter,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                                  labelStyle: TextStyle(
                                    color: AppTheme.primaryBlue,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          SizedBox(height: 16),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                _isEditing ? 'Edit Poll' : 'Create Poll',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: Icon(
                _isEditing ? Icons.edit : Icons.add_circle_outline,
                color: AppTheme.primaryBlue,
              ),
              initiallyExpanded: _isCreateExpanded,
              onExpansionChanged: (expanded) {
                if (!expanded) _clearForm();
              },
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _questionController,
                        decoration: InputDecoration(
                          labelText: 'Question',
                          hintText: 'Enter your poll question',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.question_mark),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Options',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...List.generate(
                        _optionControllers.length,
                        (index) => Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _optionControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Option ${index + 1}',
                                    hintText: 'Enter option ${index + 1}',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: Icon(Icons.radio_button_unchecked),
                                  ),
                                ),
                              ),
                              if (_optionControllers.length > 2)
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline),
                                  onPressed: () => _removeOption(index),
                                  color: Theme.of(context).colorScheme.error,
                                ),
                            ],
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addOption,
                        icon: Icon(Icons.add),
                        label: Text('Add Option'),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: _clearForm,
                            icon: Icon(Icons.clear),
                            label: Text('Clear'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _savePoll,
                            icon: Icon(_isEditing ? Icons.save : Icons.send),
                            label: Text(_isEditing ? 'Update' : 'Create'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Active Polls',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('polls')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.poll_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No polls yet',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var poll = snapshot.data!.docs[index];
                    var endDate = (poll['endDate'] as Timestamp).toDate();
                    var createdAt = (poll['createdAt'] as Timestamp).toDate();

                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _showPollDetails(poll),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      poll['question'],
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, color: AppTheme.primaryBlue),
                                        onPressed: () => _editPoll(poll),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Delete Poll'),
                                            content: Text('Are you sure you want to delete this poll?'),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deletePoll(poll.id);
                                                },
                                                child: Text(
                                                  'Delete',
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Created on ${DateFormat('MMM dd, yyyy').format(createdAt)}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Ends on ${DateFormat('MMM dd, yyyy').format(endDate)}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 16),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('polls')
                                    .doc(poll.id)
                                    .collection('votes')
                                    .snapshots(),
                                builder: (context, votesSnapshot) {
                                  final totalVotes = votesSnapshot.data?.docs.length ?? 0;
                                  return Text(
                                    'Total Votes: $totalVotes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _AdsApprovalTab extends StatefulWidget {
  @override
  _AdsApprovalTabState createState() => _AdsApprovalTabState();
}

class _AdsApprovalTabState extends State<_AdsApprovalTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: AppTheme.mediumGrey,
            indicatorColor: AppTheme.primaryBlue,
            labelStyle: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            unselectedLabelStyle: AppTheme.bodyMedium,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAdsList('pending'),
              _buildAdsList('approved'),
              _buildAdsList('rejected'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdsList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ads')
          .where('status', isEqualTo: status)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'pending'
                      ? Icons.pending_actions
                      : status == 'approved'
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No ${status} advertisements',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final ad = snapshot.data!.docs[index];
            final adData = ad.data() as Map<String, dynamic>;
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (adData['imageUrl']?.isNotEmpty ?? false)
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        adData['imageUrl'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: AppTheme.lightGrey,
                          child: Icon(Icons.broken_image, size: 64, color: AppTheme.mediumGrey),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    adData['title']?.toString() ?? 'No Title',
                                    style: AppTheme.titleLarge,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'By: ${adData['advertiserEmail'] ?? 'Unknown Advertiser'}',
                                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.mediumGrey),
                                  ),
                                ],
                              ),
                            ),
                            if (status == 'pending')
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.check_circle),
                                    color: Colors.green,
                                    onPressed: () => _updateAdStatus(ad.reference, 'approved'),
                                    tooltip: 'Approve',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.cancel),
                                    color: Colors.red,
                                    onPressed: () => _showRejectDialog(ad.reference),
                                    tooltip: 'Reject',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    color: Colors.grey,
                                    onPressed: () => _deleteAd(ad.reference),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (status == 'rejected')
                                    Text(
                                      'Rejected',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  if (status == 'approved')
                                    Text(
                                      'Approved',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    color: Colors.grey,
                                    onPressed: () => _deleteAd(ad.reference),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          adData['description']?.toString() ?? 'No Description',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Submitted: ${DateFormat('MMM d, y').format(adData['timestamp'].toDate())}',
                              style: TextStyle(color: Colors.grey),
                            ),
                            if (status != 'pending')
                              Chip(
                                label: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: status == 'approved' ? Colors.green : Colors.red,
                              ),
                          ],
                        ),
                        if (status == 'rejected' && adData['rejectionReason'] != null)
                          Container(
                            margin: EdgeInsets.only(top: 8),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Rejection Reason: ${adData['rejectionReason']}',
                                    style: TextStyle(color: Colors.red[900]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateAdStatus(DocumentReference adRef, String status, [String? rejectionReason]) async {
    setState(() => _isLoading = true);
    try {
      await adRef.update({
        'status': status,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Advertisement ${status == 'approved' ? 'approved' : 'rejected'} successfully'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating advertisement status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _showRejectDialog(DocumentReference adRef) async {
    final TextEditingController reasonController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Advertisement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide a reason for rejection:'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
                hintText: 'Enter the reason for rejection',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please provide a rejection reason')),
                );
                return;
              }
              Navigator.pop(context);
              _updateAdStatus(adRef, 'rejected', reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAd(DocumentReference adRef) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Advertisement'),
        content: Text('Are you sure you want to delete this advertisement? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await adRef.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Advertisement deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting advertisement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _IssuesTab extends StatefulWidget {
  @override
  _IssuesTabState createState() => _IssuesTabState();
}

class _IssuesTabState extends State<_IssuesTab> {
  String _statusFilter = 'all';
  String _sortBy = 'date';
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _checkAndUpdateMissingDates();
  }

  Future<void> _checkAndUpdateMissingDates() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('issues')
        .where('createdAt', isNull: true)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({
        'createdAt': doc.data().toString().contains('timestamp') 
            ? doc['timestamp']  // Use existing timestamp if available
            : FieldValue.serverTimestamp(),  // Otherwise use current time
      });
    }
  }

  final List<String> _statusOptions = [
    'reported',
    'in progress',
    'resolved',
    'closed'
  ];

  final Map<String, String> _sortOptions = {
    'date': 'createdAt',
    'status': 'status',
  };

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reported':
        return Colors.red;
      case 'in progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatLocation(dynamic location) {
    if (location == null) return 'No location specified';
    if (location is GeoPoint) {
      return '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
    }
    if (location is String) {
      return location;
    }
    if (location is Map) {
      if (location.containsKey('address')) return location['address'];
      if (location.containsKey('latitude') && location.containsKey('longitude')) {
        return '${location['latitude']}, ${location['longitude']}';
      }
    }
    return 'Location format unknown';
  }

  Future<void> _deleteIssue(BuildContext context, DocumentReference ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Issue'),
        content: Text('Are you sure you want to delete this issue? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Issue deleted successfully')),
      );
    }
  }

  void _updateStatus(BuildContext context, DocumentReference ref, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(
              _statusOptions.length,
              (index) => ListTile(
                leading: Icon(
                  Icons.circle,
                  color: _getStatusColor(_statusOptions[index]),
                  size: 16,
                ),
                title: Text(_statusOptions[index]),
                selected: currentStatus == _statusOptions[index],
                onTap: () {
                  ref.update({'status': _statusOptions[index]});
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showIssueDetails(BuildContext context, DocumentSnapshot issue) {
    final data = issue.data() as Map<String, dynamic>?;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.circle,
              color: _getStatusColor(data?['status'] ?? ''),
              size: 16,
            ),
            SizedBox(width: 8),
            Expanded(child: Text(_getIssueTitle(issue))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data != null && data.containsKey('description') && data['description'] != null) ...[
                Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(data['description']),
                SizedBox(height: 16),
              ],
              Text(
                'Location',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(_formatLocation(data?['location'])),
              SizedBox(height: 16),
              Text(
                'Reported by',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(data?['reportedBy'] ?? 'Anonymous'),
              SizedBox(height: 16),
              Text(
                'Date Reported',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                data?['createdAt'] != null
                    ? DateFormat('MMM dd, yyyy HH:mm').format((data!['createdAt'] as Timestamp).toDate())
                    : 'Unknown date'
              ),
              if (data != null && data['imageUrl'] != null) ...[
                SizedBox(height: 16),
                Text(
                  'Attached Image',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    data['imageUrl'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return CircularProgressIndicator();
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        Text('Error loading image'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getIssueTitle(DocumentSnapshot issue) {
    // Try to get title, if not available use first line of description or fallback text
    if (issue.data() != null) {
      final data = issue.data() as Map<String, dynamic>;
      if (data.containsKey('title') && data['title'] != null) {
        return data['title'].toString();
      }
      if (data.containsKey('description') && data['description'] != null) {
        final description = data['description'].toString();
        // Return first line of description or whole if it's short
        final firstLine = description.split('\n').first;
        return firstLine.length > 50 ? '${firstLine.substring(0, 47)}...' : firstLine;
      }
    }
    return 'Untitled Issue';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _statusFilter,
                    isExpanded: true,
                    dropdownColor: Theme.of(context).cardColor,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white : null,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Filter by Status',
                      filled: true,
                      fillColor: isDark ? Color(0xFF2C2C2C) : AppTheme.lightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : AppTheme.mediumGrey,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text(
                          'All Issues',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.darkGrey,
                          ),
                        ),
                      ),
                      ..._statusOptions.map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: _getStatusColor(status), size: 16),
                              SizedBox(width: 8),
                              Text(
                                status,
                                style: TextStyle(
                                  color: isDark ? Colors.white : AppTheme.darkGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _statusFilter = value!),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _sortBy,
                    isExpanded: true,
                    dropdownColor: Theme.of(context).cardColor,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white : null,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Sort by',
                      filled: true,
                      fillColor: isDark ? Color(0xFF2C2C2C) : AppTheme.lightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white70 : AppTheme.mediumGrey,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'date',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 20, color: Theme.of(context).primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Date',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppTheme.darkGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'status',
                        child: Row(
                          children: [
                            Icon(Icons.label, size: 20, color: Theme.of(context).primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Status',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppTheme.darkGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() {
                      _sortBy = value!;
                      _sortDescending = value == 'date';
                    }),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Issues List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('issues')
                  .where(_sortBy == 'date' ? 'createdAt' : 'status', isNull: false)  // Only get documents with the field
                  .orderBy(_sortOptions[_sortBy]!, descending: _sortDescending)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                var issues = snapshot.data!.docs;

                // Secondary sort by createdAt for status sorting to maintain consistency
                if (_sortBy == 'status') {
                  issues = List.from(issues)
                    ..sort((a, b) {
                      int statusCompare = (a['status'] ?? '').compareTo(b['status'] ?? '');
                      if (statusCompare == 0 && a['createdAt'] != null && b['createdAt'] != null) {
                        return _sortDescending
                            ? (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp)
                            : (a['createdAt'] as Timestamp).compareTo(b['createdAt'] as Timestamp);
                      }
                      return statusCompare;
                    });
                }

                if (_statusFilter != 'all') {
                  issues = issues.where((doc) => doc['status'] == _statusFilter).toList();
                }

                if (issues.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No issues found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        if (_sortBy == 'date') ...[
                          SizedBox(height: 8),
                          Text(
                            'Try changing the sort order or check if issues have dates',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: issues.length,
                  itemBuilder: (context, index) {
                    var issue = issues[index];
                    final data = issue.data() as Map<String, dynamic>?;
                    if (data == null) return SizedBox.shrink();
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _showIssueDetails(context, issue),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: _getStatusColor(data['status'] ?? ''),
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _getIssueTitle(issue),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit),
                                            SizedBox(width: 8),
                                            Text('Update Status'),
                                          ],
                                        ),
                                        onTap: () => Future.delayed(
                                          Duration(seconds: 0),
                                          () => _updateStatus(context, issue.reference, data['status'] ?? ''),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                        onTap: () => Future.delayed(
                                          Duration(seconds: 0),
                                          () => _deleteIssue(context, issue.reference),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (data.containsKey('description') && data['description'] != null) ...[
                                SizedBox(height: 8),
                                Text(
                                  data['description'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatLocation(data['location']),
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    data['createdAt'] != null
                                        ? DateFormat('MMM dd, yyyy').format((data['createdAt'] as Timestamp).toDate())
                                        : 'Unknown date',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _UserManagementTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ));

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var userDoc = snapshot.data!.docs[index];
            var email = userDoc['email'];
            var role = userDoc['role'];
            var uid = userDoc.id;

            return Card(
              margin: EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  email,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.darkGrey,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Role: $role',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppTheme.mediumGrey,
                    fontSize: 14,
                  ),
                ),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF2C2C2C) : AppTheme.lightGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: DropdownButton<String>(
                    value: role,
                    underline: SizedBox(),
                    dropdownColor: Theme.of(context).cardColor,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.darkGrey,
                      fontSize: 14,
                    ),
                    items: ['citizen', 'advertiser', 'admin']
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                r,
                                style: TextStyle(
                                  color: isDark ? Colors.white : AppTheme.darkGrey,
                                  fontSize: 14,
                                ),
                              ),
                            ))
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
                ),
              ),
            );
          },
        );
      },
    );
  }
}
