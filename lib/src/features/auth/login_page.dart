import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../core/services/auth_storage.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';

class LoginPage extends StatefulWidget {
  static const route = '/login';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _apiService = ApiService();

  Future<void> _handleLogin() async {
    // Validate inputs
    if (email.text.trim().isEmpty) {
      _showSnackBar('Please enter your email');
      return;
    }
    if (pass.text.trim().isEmpty) {
      _showSnackBar('Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.login(
        email: email.text.trim(),
        password: pass.text.trim(),
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        // Save token and user data
        final data = result['data'];
        if (data != null && data['token'] != null && data['user'] != null) {
          // Print token to console
          print('====================================');
          print('LOGIN SUCCESS');
          print('====================================');
          print('Token: ${data['token']}');
          print('User: ${data['user']}');
          print('====================================');

          await AuthStorage.saveAuth(
            token: data['token'],
            user: data['user'],
          );

          // Navigate to app
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/app');
          }
        } else {
          _showSnackBar('Login response missing token or user data');
        }
      } else {
        _showSnackBar(result['message'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('An error occurred. Please try again.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome Back! 👋',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text("Glad to have you here again. Let's get started!",
                  style: TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 22),
              const Text('Email',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Enter your email',
                controller: email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefix: const Icon(Icons.email_outlined),
              ),
              const SizedBox(height: 16),
              const Text('Password',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Enter your password',
                controller: pass,
                obscure: _obscurePassword,
                textInputAction: TextInputAction.done,
                prefix: const Icon(Icons.lock_outline),
                suffix: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  child: const Text('Forgot Password?',
                      style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                  label: _isLoading ? 'Signing In...' : 'Sign In',
                  onPressed: _isLoading ? () {} : _handleLogin),
              const SizedBox(height: 18),
              Row(children: const [
                Expanded(child: Divider()),
                SizedBox(width: 12),
                Text('Or continue with'),
                SizedBox(width: 12),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _Social('assets/icons/google.png'),
                  SizedBox(width: 16),
                  _Social('assets/icons/apple.png'),
                  SizedBox(width: 16),
                  _Social('assets/icons/facebook.png'),
                ],
              ),
              const SizedBox(height: 22),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("Don't have an account? "),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/signup'),
                  child: const Text('Sign Up',
                      style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Social extends StatelessWidget {
  final String path;
  const _Social(this.path);

  @override
  Widget build(BuildContext context) {
    return Ink(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Center(child: Image.asset(path, width: 22, height: 22)),
      ),
    );
  }
}
