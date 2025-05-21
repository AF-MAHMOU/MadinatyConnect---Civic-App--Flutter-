import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_localizations.dart';
import '../../utils/dark_mode_helper.dart';
import '../../main.dart';
import 'signup_screen.dart';
import '../citizen/citizen_dashboard.dart';
import '../government/admin_dashboard.dart';
import '../advertiser/advertiser_dashboard.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  AnimationController? _animationController;
  Animation<double>? _formAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && mounted) {
        _navigateBasedOnRole(user);
      }
    });
  }

  Future<void> _initializeAnimations() async {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _formAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.fastOutSlowIn,
    );
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _animationController!.forward();
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (userCredential.user != null) {
        await _navigateBasedOnRole(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = switch (e.code) {
        'user-not-found' => 'No user found with this email.',
        'wrong-password' => 'Wrong password provided.',
        'invalid-email' => 'The email address is invalid.',
        'user-disabled' => 'This user account has been disabled.',
        _ => 'An error occurred: ${e.message}',
      };
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateBasedOnRole(User user) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!mounted) return;
      final role = userDoc.data()?['role'] as String? ?? 'citizen';

      Widget dashboard = switch (role) {
        'admin' => AdminDashboard(),
        'advertiser' => AdvertiserDashboard(),
        _ => CitizenDashboard(),
      };

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => dashboard,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CitizenDashboard()),
        );
      }
    }
  }

  Widget _buildAnimatedFormField({
    required Widget child,
    double offsetY = 0.3,
    int index = 0,
  }) {
    if (_animationController == null || _formAnimation == null) {
      return child; // Return unanimated widget if animations aren't ready
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, offsetY),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController!,
          curve: Interval(
            0.1 + (0.1 * index),
            1.0,
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: FadeTransition(
        opacity: _formAnimation!,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_animationController == null || _formAnimation == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      );
    }

    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final fillColor = isDark ? Colors.grey[800] : Colors.grey[100];

    return DarkModeHelper.addDarkModeToggle(
      Scaffold(
        appBar: AppBar(
          title: Text(localizations.translate('login')),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.language, color: Theme.of(context).primaryColor),
              onPressed: () {
                final currentLocale = localizations.currentLanguage;
                final newLocale = currentLocale == 'en' ? Locale('ar') : Locale('en');
                MyApp.of(context)?.setLocale(newLocale);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _animationController!,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          -15 * (1 - _animationController!.value),
                        ),
                        child: Opacity(
                          opacity: _animationController!.value,
                          child: child,
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildAnimatedFormField(
                    index: 0,
                    child: Text(
                      localizations.translate('welcome_back'),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildAnimatedFormField(
                    index: 1,
                    offsetY: 0.2,
                    child: Text(
                      localizations.translate('login_subtitle'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: textColor.withOpacity(0.8),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildAnimatedFormField(
                    index: 2,
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: fillColor,
                        hintText: localizations.translate('email_hint'),
                        labelText: localizations.translate('email'),
                        labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                        prefixIcon: Icon(Icons.email, color: Theme.of(context).primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('email_required');
                        }
                        if (!value.contains('@')) {
                          return localizations.translate('invalid_email');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAnimatedFormField(
                    index: 3,
                    offsetY: 0.4,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: fillColor,
                        hintText: localizations.translate('password_hint'),
                        labelText: localizations.translate('password'),
                        labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                        prefixIcon: Icon(Icons.lock, color: Theme.of(context).primaryColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: iconColor,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('password_required');
                        }
                        if (value.length < 6) {
                          return localizations.translate('password_length');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildAnimatedFormField(
                    index: 4,
                    offsetY: 0.5,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColorDark,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                localizations.translate('login'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAnimatedFormField(
                    index: 5,
                    offsetY: 0.6,
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: textColor.withOpacity(0.2), thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            localizations.translate('or'),
                            style: TextStyle(color: textColor.withOpacity(0.6)),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: textColor.withOpacity(0.2), thickness: 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAnimatedFormField(
                    index: 6,
                    offsetY: 0.7,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(milliseconds: 500),
                            pageBuilder: (_, __, ___) => SignupScreen(),
                            transitionsBuilder: (_, animation, __, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      child: Text.rich(
                        TextSpan(
                          text: localizations.translate('no_account'),
                          children: [
                            TextSpan(
                              text: localizations.translate('sign_up'),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textColor,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}