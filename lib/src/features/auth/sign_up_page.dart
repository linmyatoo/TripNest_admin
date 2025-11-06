import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';

class SignUpPage extends StatefulWidget {
  static const route = '/signup';
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agreedToPolicy = false;
  final _apiService = ApiService();

  Future<void> _handleSignUp() async {
    // Check if user agreed to policy
    if (!_agreedToPolicy) {
      _showSnackBar(
          'Please agree to the Terms and Conditions and Privacy Notice');
      return;
    }

    // Validate inputs
    if (name.text.trim().isEmpty) {
      _showSnackBar('Please enter your name');
      return;
    }
    if (email.text.trim().isEmpty) {
      _showSnackBar('Please enter your email');
      return;
    }
    if (password.text.trim().isEmpty) {
      _showSnackBar('Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.register(
        username: name.text.trim(),
        email: email.text.trim(),
        password: password.text.trim(),
        role: 'admin', // Admin role for admin app
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => _SignUpSuccessDialog(
              username: name.text.trim(),
            ),
          );
        }
      } else {
        _showSnackBar(result['message'] ?? 'Registration failed');
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
              const Text('Create Your Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text(
                  "Join us today and unlock endless possibilities. It's quick, easy, and just a step away!",
                  style: TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 22),
              const Text('Full Name',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Enter your name',
                controller: name,
                textInputAction: TextInputAction.next,
                prefix: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: 16),
              const Text('Phone Number',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Enter your number',
                controller: phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                prefix: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Image.asset('assets/images/flag_th.png',
                        width: 22, height: 22),
                    const SizedBox(width: 8),
                    const Text('+66',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    const VerticalDivider(width: 1.0, thickness: 1.0),
                    const SizedBox(width: 4),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
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
                controller: password,
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
              const SizedBox(height: 22),
              PrimaryButton(
                label: _isLoading ? 'Signing Up...' : 'Sign Up',
                onPressed: _isLoading ? () {} : _handleSignUp,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _agreedToPolicy,
                        onChanged: (value) {
                          setState(() {
                            _agreedToPolicy = value ?? false;
                          });
                        },
                      )),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Wrap(
                      children: [
                        Text('By creating an account, you must agree to our '),
                        _Blue('Terms and Conditions'),
                        Text(' and '),
                        _Blue('Privacy Notice'),
                        Text('.'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Already have an account? '),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const _Blue('Sign In'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Blue extends StatelessWidget {
  final String text;
  const _Blue(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style:
            TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600));
  }
}

class _SignUpSuccessDialog extends StatelessWidget {
  final String username;
  const _SignUpSuccessDialog({required this.username});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Blue check with soft halo
          Container(
            width: 86,
            height: 86,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFDDEBFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB), // AppColors.primary
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 36),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your registration is successful!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            "Thanks for joining us\nLet's make memories together",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),

          // Full-width primary button (rounded, like the mock)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Login Now',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}
