import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madinatyconnect/screens/chat_request_screen.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'home_screen.dart';
import 'poll_screen.dart';
import 'report_issue_screen.dart';
import 'emergency_screen.dart';
import '../../utils/dark_mode_helper.dart';
import '../../utils/app_localizations.dart';
import '../../utils/app_theme.dart';
import '../../main.dart';

class CitizenDashboard extends StatefulWidget {
  @override
  _CitizenDashboardState createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _showAnnouncement = false;
  Map<String, dynamic>? _latestAnnouncement;

  final List<Widget> _screens = [
    HomeScreen(),
    PollScreen(),
    ReportIssueScreen(),
    ChatRequestScreen(),
    EmergencyScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    // Listen for new announcements
    FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _latestAnnouncement = snapshot.docs.first.data();
          _showAnnouncement = true;
        });
        _animationController.forward();
        // Keep showing until manually dismissed
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final namePart = parts[0];
    final domainPart = parts[1];

    if (namePart.isEmpty) return '@$domainPart';
    
    final maskedName = namePart.length <= 2 
        ? '${namePart[0]}*' 
        : '${namePart.substring(0, 2)}***';

    return '$maskedName@$domainPart';
  }

  Future<void> _logout() async {
    try {
      await AuthService().logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildUserInfo(User? currentUser, AppLocalizations localizations) {
    return Container(
      color: AppTheme.primaryBlue,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 24,
            child: Icon(
              Icons.person,
              size: 30,
              color: AppTheme.primaryBlue,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: currentUser == null
                ? Text(
                    localizations.translate('guest_user'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  )
                : FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Text(
                          localizations.translate('loading'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        );
                      }

                      final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                      final userName = userData['name']?.toString() ?? '';
                      final email = userData['email']?.toString() ?? '';
                      final maskedEmail = _maskEmail(email);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (userName.isNotEmpty)
                            Text(
                              userName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (maskedEmail.isNotEmpty)
                            Text(
                              maskedEmail,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementBanner() {
    if (!_showAnnouncement || _latestAnnouncement == null) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      color: AppTheme.primaryBlue.withOpacity(0.9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.announcement, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _latestAnnouncement!['title'] ?? 'New Announcement',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  _latestAnnouncement!['message'] ?? '',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: () {
              setState(() => _showAnnouncement = false);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    return DarkModeHelper.addDarkModeToggle(
      Scaffold(
        appBar: AppBar(
          title: AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            child: Text(
              localizations.translate('citizen_dashboard'),
              key: ValueKey(_currentIndex),
              style: TextStyle(fontSize: 18),
            ),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.language, size: 22),
                    onPressed: () {
                      final currentLocale = localizations.currentLanguage;
                      final newLocale = currentLocale == 'en' ? Locale('ar') : Locale('en');
                      MyApp.of(context)?.setLocale(newLocale);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.logout, size: 22),
                    onPressed: _logout,
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildUserInfo(currentUser, localizations),
            _buildAnnouncementBanner(),
            Expanded(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                child: _screens[_currentIndex],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: Colors.grey,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 22),
              activeIcon: Icon(Icons.home, size: 22),
              label: localizations.translate('home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.poll_outlined, size: 22),
              activeIcon: Icon(Icons.poll, size: 22),
              label: localizations.translate('polls'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_outlined, size: 22),
              activeIcon: Icon(Icons.report_problem, size: 22),
              label: localizations.translate('report'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_outlined, size: 22),
              activeIcon: Icon(Icons.chat, size: 22),
              label: localizations.translate('chat'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emergency_outlined, size: 22),
              activeIcon: Icon(Icons.emergency, size: 22),
              label: localizations.translate('emergency'),
            ),
          ],
        ),
      ),
    );
  }
}