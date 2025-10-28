import 'package:flutter/material.dart';
import 'src/app_shell.dart';
import 'src/features/splash/admin_splash_page.dart';
import 'src/features/onboarding/onboarding_page.dart';
import 'src/features/auth/login_page.dart';
import 'src/features/auth/sign_up_page.dart';
import 'src/features/home/home_page.dart';
import 'src/features/reviews/reviews_page.dart';
import 'src/features/sales/sales_page.dart';
import 'src/features/profile/profile_page.dart';
import 'src/core/theme/app_colors.dart';

import 'src/features/create/create_event_page.dart';
import 'src/features/profile/personal_data_page.dart';
import 'src/features/profile/security_page.dart';
import 'src/features/profile/notifications_settings_page.dart';
import 'src/features/profile/privacy_policy_page.dart';
import 'src/features/profile/help_center_page.dart';
import 'src/features/profile/change_password_page.dart';
import 'src/features/notifications/notification_feed_page.dart';

void main() {
  runApp(const TripNestApp());
}

class TripNestApp extends StatelessWidget {
  const TripNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TripNest',
      theme: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.primary,
        ),
        // App background
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),

        // Bottom NavigationBar (Material 3 NavigationBar)
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0x1A2563EB),
          surfaceTintColor: Colors.transparent,
        ),

        // All text inputs: white + outline + clear focus ring
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.primary, width: 1.6),
          ),
        ),

        textTheme: base.textTheme.apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),

        // Top app bar matches background
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFFF4F6F8),
          foregroundColor: AppColors.textPrimary,
          surfaceTintColor: Colors.transparent,
        ),

        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      initialRoute: AdminSplashPage.route,
      routes: {
        AdminSplashPage.route: (_) => const AdminSplashPage(),
        OnboardingPage.route: (_) => const OnboardingPage(),
        LoginPage.route: (_) => const LoginPage(),
        SignUpPage.route: (_) => const SignUpPage(),
        AppShell.route: (_) => const AppShell(),
        HomePage.route: (_) => const HomePage(),
        ReviewsPage.route: (_) => const ReviewsPage(),
        SalesPage.route: (_) => const SalesPage(),
        ProfilePage.route: (_) => const ProfilePage(),

        CreateEventPage.route: (_) => const CreateEventPage(),
        PersonalDataPage.route: (_) => const PersonalDataPage(),
        SecurityPage.route: (_) => const SecurityPage(),
        NotificationsSettingsPage.route: (_) => const NotificationsSettingsPage(),
        PrivacyPolicyPage.route: (_) => const PrivacyPolicyPage(),
        HelpCenterPage.route: (_) => const HelpCenterPage(),
        ChangePasswordPage.route: (_) => const ChangePasswordPage(),
        NotificationFeedPage.route: (_) => const NotificationFeedPage(),
      },
    );
  }
}
