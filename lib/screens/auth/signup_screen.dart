import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String role = 'citizen';

  void signup() async {
    try {
      AppUser? user = await AuthService().signup(
        emailController.text.trim(),
        passwordController.text.trim(),
        role,
      );

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account created as ${user.role}")),
        );
        Navigator.pop(context); // Go back to login
      }
    } catch (e) {
      print("Signup Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Signup failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
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
            DropdownButton<String>(
              value: role,
              onChanged: (val) => setState(() => role = val!),
              items:
                  ['citizen', 'advertiser']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: signup, child: Text('Register')),
          ],
        ),
      ),
    );
  }
}
