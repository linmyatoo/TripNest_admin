import 'package:flutter/material.dart';

import '../../core/services/auth_storage.dart';

class AdminSplashPage extends StatefulWidget {
  static const route = '/';
  const AdminSplashPage({super.key});

  @override
  State<AdminSplashPage> createState() => _AdminSplashPageState();
}

class _AdminSplashPageState extends State<AdminSplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;

      // Check if user is already logged in
      if (AuthStorage.isAuthenticated()) {
        Navigator.of(context).pushReplacementNamed('/app');
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    });
  }

  // ...existing code...
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TripNest',
                style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5),
              ),
              SizedBox(height: 8),
              Text('Admin',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
// ...existing code...
}
