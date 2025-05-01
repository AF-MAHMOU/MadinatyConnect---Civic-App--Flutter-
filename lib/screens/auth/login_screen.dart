import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../citizen/citizen_dashboard.dart';
import '../government/admin_dashboard.dart';
import '../advertiser/advertiser_dashboard.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void login() async {
    try {
      AppUser? user = await AuthService().login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user == null) throw Exception('User not found');

      // Navigate based on role
      if (user.role == 'citizen') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CitizenDashboard()),
        );
      } else if (user.role == 'advertiser') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdvertiserDashboard()),
        );
      } else if (user.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboard()),
        );
      } else {
        throw Exception('Unknown user role');
      }
    } catch (e) {
      print("Login Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: login, child: Text('Login')),
            TextButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SignupScreen()),
                  ),
              child: Text("Don't have an account? Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
