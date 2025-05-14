// lib/screens/citizen/citizen_dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'home_screen.dart';
import 'poll_screen.dart';
import 'report_issue_screen.dart';
import 'emergency_screen.dart';
import '../../utils/dark_mode_helper.dart';

class CitizenDashboard extends StatefulWidget {
  @override
  _CitizenDashboardState createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(), // Announcements
    PollScreen(), // Polls
    ReportIssueScreen(), // Issue reporting
    EmergencyScreen(), // Emergency contacts
  ];

  @override
  Widget build(BuildContext context) {
    return DarkModeHelper.addDarkModeToggle(
      Scaffold(
        appBar: AppBar(
          title: Text('Citizen Dashboard'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await AuthService().logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.poll), label: 'Polls'),
            BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Report'),
            BottomNavigationBarItem(
              icon: Icon(Icons.emergency),
              label: 'Emergency',
            ),
          ],
        ),
      ),
    );
  }
}
