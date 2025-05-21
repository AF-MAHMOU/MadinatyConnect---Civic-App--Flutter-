import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_localizations.dart';
import '../../utils/dark_mode_helper.dart';
import '../../utils/ui_animations.dart';
import '../../services/auth_service.dart';
import '../../main.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  late Animation<double> _formAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _formAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

Future<void> _signup() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isLoading = true);

  try {
    await AuthService().signup(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      'citizen', // default role
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final fillColor = isDark ? Colors.grey[800] : Colors.grey[100];

    return DarkModeHelper.addDarkModeToggle(
      Scaffold(
        appBar: AppBar(
          title: Text(localizations.translate('sign_up')),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).primaryColor),
            onPressed: () => Navigator.pop(context),
          ),
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
                  const AnimatedLogo(size: 120),
                  const SizedBox(height: 32),
                  FadeSlideTransition(
                    animation: _formAnimation,
                    child: Text(
                      localizations.translate('create_account'),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeSlideTransition(
                    animation: _formAnimation,
                    offset: const Offset(0, 0.2),
                    child: Text(
                      localizations.translate('signup_subtitle'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: textColor.withOpacity(0.8),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeSlideTransition(
                    animation: _formAnimation,
                    offset: const Offset(0, 0.3),
                    child: TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: fillColor,
                        hintText: localizations.translate('full_name_hint'),
                        labelText: localizations.translate('full_name'),
                        labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                        prefixIcon: Icon(Icons.person, color: Theme.of(context).primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('name_required');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideTransition(
                    animation: _formAnimation,
                    offset: const Offset(0, 0.4),
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
                  const SizedBox(height: 16),
                  FadeSlideTransition(
                    animation: _formAnimation,
                    offset: const Offset(0, 0.5),
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
                  const SizedBox(height: 16),
                  FadeSlideTransition(
                    animation: _formAnimation,
                    offset: const Offset(0, 0.6),
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: fillColor,
                        hintText: localizations.translate('confirm_password_hint'),
                        labelText: localizations.translate('confirm_password'),
                        labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                        prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).primaryColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: iconColor,
                          ),
                          onPressed: () =>
                              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('confirm_password_required');
                        }
                        if (value != _passwordController.text) {
                          return localizations.translate('passwords_not_match');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideTransition(
                    animation: _formAnimation,
                    offset: const Offset(0, 0.7),
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
                        onPressed: _isLoading ? null : _signup,
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
                                localizations.translate('sign_up'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeSlideTransition(
                    animation: _formAnimation,
                    offset: const Offset(0, 0.8),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text.rich(
                        TextSpan(
                          text: localizations.translate('have_account'),
                          children: [
                            TextSpan(
                              text: localizations.translate('login'),
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