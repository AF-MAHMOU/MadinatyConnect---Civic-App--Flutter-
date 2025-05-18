import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import '../../utils/dark_mode_helper.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentTab = 0;
  bool _isLoading = false;

  String _getAppBarTitle() {
    switch (_currentTab) {
      case 0:
        return 'Announcements';
      case 1:
        return 'Community Polls';
      case 2:
        return 'Advertisement Management';
      case 3:
        return 'Issue Reports';
      case 4:
        return 'User Management';
      default:
        return 'Admin Dashboard';
    }
  }

  Widget _getCurrentTab() {
    switch (_currentTab) {
      case 0:
        return _AnnouncementsTab();
      case 1:
        return _PollsTab();
      case 2:
        return _AdsApprovalTab();
      case 3:
        return _IssuesTab();
      case 4:
        return _UserManagementTab();
      default:
        return _AnnouncementsTab();
    }
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
                await FirebaseAuth.instance.signOut();
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
    return DarkModeHelper.addDarkModeToggle(
      Scaffold(
        appBar: AppBar(
          title: Text(
            _getAppBarTitle(),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: Stack(
                children: [
                  Icon(Icons.notifications_outlined),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '5',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                // TODO: Implement notifications
              },
              tooltip: 'Notifications',
            ),
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _showLogoutDialog,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    color: Theme.of(context).cardColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                _currentTab == 0
                                    ? Icons.announcement
                                    : _currentTab == 1
                                        ? Icons.poll
                                        : _currentTab == 2
                                            ? Icons.ad_units
                                            : _currentTab == 3
                                                ? Icons.report_problem
                                                : Icons.manage_accounts,
                                color: Theme.of(context).primaryColor,
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _getAppBarTitle(),
                                  style: Theme.of(context).textTheme.titleLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        _buildActionButton(),
                      ],
                    ),
                  ),
                  Expanded(child: _getCurrentTab()),
                ],
              ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (index) => setState(() => _currentTab = index),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.announcement_outlined),
              activeIcon: Icon(Icons.announcement),
              label: 'Announcements',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.poll_outlined),
              activeIcon: Icon(Icons.poll),
              label: 'Polls',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.ad_units_outlined),
              activeIcon: Icon(Icons.ad_units),
              label: 'Ads',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_outlined),
              activeIcon: Icon(Icons.report_problem),
              label: 'Issues',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts_outlined),
              activeIcon: Icon(Icons.manage_accounts),
              label: 'Users',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    switch (_currentTab) {
      case 0:
        return Container();
      case 1:
        return Container();
      case 2:
        return Container();
      case 3:
        return ElevatedButton.icon(
          onPressed: () {
            // TODO: Implement export issues
          },
          style: AppTheme.primaryButton,
          icon: Icon(Icons.download),
          label: Text('Export Issues'),
        );
      case 4:
        return ElevatedButton.icon(
          onPressed: () {
            // TODO: Implement add user
          },
          style: AppTheme.primaryButton,
          icon: Icon(Icons.person_add),
          label: Text('Add User'),
        );
      default:
        return Container();
    }
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
    });
  }

  void _editAnnouncement(DocumentSnapshot doc) {
    _titleController.text = doc['title'];
    _contentController.text = doc['description'];
    setState(() {
      _isEditing = true;
      _editingId = doc.id;
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
            child: ExpansionTile(
              title: Text(
                'Create Announcement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              leading: Icon(Icons.add_circle_outline),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: AppTheme.inputDecoration('Title', hint: 'Enter a clear, concise title'),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _contentController,
                        maxLines: 5,
                        decoration: AppTheme.inputDecoration(
                          'Content',
                          hint: 'Enter the announcement details...',
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _clearForm,
                            child: Text('Clear'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _saveAnnouncement,
                            icon: Icon(_isEditing ? Icons.save : Icons.send),
                            label: Text(_isEditing ? 'Update' : 'Post'),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          // Announcements List
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
                    child: Text(
                      'No announcements yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
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
                      child: ListTile(
                        title: Text(
                          doc['title'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                              doc['description'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Posted on ${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
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
                              icon: Icon(Icons.edit, color: Colors.blue),
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
                                    'Posted on ${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
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

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _createPoll() async {
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
      await FirebaseFirestore.instance.collection('polls').add({
        'question': _questionController.text.trim(),
        'options': options,
        'endDate': Timestamp.fromDate(
          DateTime.now().add(Duration(days: 7)),
        ),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _questionController.clear();
      for (var controller in _optionControllers) {
        controller.clear();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Poll created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating poll: $e')),
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
                            style: Theme.of(context).textTheme.titleLarge,
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 16),
                    ...votesByOption.entries.map((entry) {
                      final percentage = votes.isEmpty
                          ? 0.0
                          : (entry.value.length / votes.length) * 100;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key} (${entry.value.length} votes - ${percentage.toStringAsFixed(1)}%)',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Theme.of(context).dividerColor,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
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
                                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: ExpansionTile(
              title: Text(
                'Create Poll',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              leading: Icon(Icons.add_circle_outline),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _questionController,
                        decoration: AppTheme.inputDecoration('Question', hint: 'Enter your poll question'),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Options',
                        style: Theme.of(context).textTheme.titleMedium,
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
                                  decoration: AppTheme.inputDecoration(
                                    'Option ${index + 1}',
                                    hint: 'Enter option ${index + 1}',
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
                      ElevatedButton(
                        onPressed: _createPoll,
                        child: Text('Create Poll'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('polls')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var poll = snapshot.data!.docs[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
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
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () {
                                      poll.reference.delete();
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Total Votes: ${votes.length}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SizedBox(height: 16),
                              ...votesByOption.entries.map((entry) {
                                final percentage = votes.isEmpty
                                    ? 0.0
                                    : (entry.value.length / votes.length) * 100;
                                
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${entry.key} (${entry.value.length} votes - ${percentage.toStringAsFixed(1)}%)',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: percentage / 100,
                                        backgroundColor: Theme.of(context).dividerColor,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Theme.of(context).primaryColor,
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
                                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
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
