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
import '../../utils/app_localizations.dart';
import '../../utils/app_theme.dart';
import '../../main.dart';

class CitizenDashboard extends StatefulWidget {
  @override
  _CitizenDashboardState createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    PollScreen(),
    ReportIssueScreen(),
    EmergencyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return DarkModeHelper.addDarkModeToggle(
      Scaffold(
        appBar: AppBar(
          title: Text(localizations.translate('citizen_dashboard')),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.language),
              onPressed: () {
                final currentLocale = AppLocalizations.of(context).currentLanguage;
                final newLocale = currentLocale == 'en' ? Locale('ar') : Locale('en');
                MyApp.of(context)?.setLocale(newLocale);
              },
            ),
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
        body: Column(
          children: [
            Container(
              color: AppTheme.primaryBlue,
              padding: EdgeInsets.only(bottom: 16),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 30,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FirebaseAuth.instance.currentUser?.email ?? '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              localizations.translate('citizen'),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: localizations.translate('home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.poll),
              label: localizations.translate('polls'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem),
              label: localizations.translate('report'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emergency),
              label: localizations.translate('emergency'),
            ),
          ],
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}
