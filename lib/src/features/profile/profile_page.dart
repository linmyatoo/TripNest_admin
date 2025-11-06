import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../core/services/auth_storage.dart';
import '../../core/widgets/settings_tile.dart';
import '../notifications/notification_feed_page.dart';
import 'change_password_page.dart';
import 'help_center_page.dart';
import 'notifications_settings_page.dart';
import 'personal_data_page.dart';
import 'privacy_policy_page.dart';
import 'security_page.dart';

class ProfilePage extends StatelessWidget {
  static const route = '/profile';
  const ProfilePage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final apiService = ApiService();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await apiService.logout();

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);

        // Navigate to login and clear all routes
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (_) => false,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);

        // Even on error, clear local storage and logout
        await AuthStorage.clearAuth();
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get user data from auth storage
    final user = AuthStorage.getUser();
    final username = user?['username'] ?? 'User';
    final email = user?['email'] ?? 'user@example.com';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                const CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        AssetImage('assets/images/avatar_jacob.jpg')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(email,
                            style: const TextStyle(color: Color(0xFF6B7280))),
                      ]),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () =>
                      Navigator.pushNamed(context, NotificationFeedPage.route),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text('General',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            SettingsTile(
                icon: Icons.person_outline,
                label: 'Edit Profile',
                onTap: () =>
                    Navigator.pushNamed(context, PersonalDataPage.route)),
            const SizedBox(height: 10),
            SettingsTile(
                icon: Icons.lock_outline,
                label: 'Change Password',
                onTap: () =>
                    Navigator.pushNamed(context, ChangePasswordPage.route)),
            const SizedBox(height: 10),
            SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () => Navigator.pushNamed(
                    context, NotificationsSettingsPage.route)),
            const SizedBox(height: 10),
            SettingsTile(
                icon: Icons.shield_outlined,
                label: 'Security',
                onTap: () => Navigator.pushNamed(context, SecurityPage.route)),
            const SizedBox(height: 18),
            const Text('Preferences',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            SettingsTile(
                icon: Icons.policy_outlined,
                label: 'Legal and Policies',
                onTap: () =>
                    Navigator.pushNamed(context, PrivacyPolicyPage.route)),
            const SizedBox(height: 10),
            SettingsTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () =>
                    Navigator.pushNamed(context, HelpCenterPage.route)),
            const SizedBox(height: 10),
            SettingsTile(
              icon: Icons.logout_rounded,
              iconColor: Color(0xFFEF4444),
              label: 'Logout',
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => const _LogoutConfirmDialog(),
                );
                if (ok == true && context.mounted) {
                  await _handleLogout(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      child: Container(
        // ↓ less top padding, a touch more bottom = text sits higher
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              IconButton(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
              ),
              const Spacer(),
            ]),
            const SizedBox(height: 6), // was 6

            const Text(
              'Are you sure you want\nto logout?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.2, // tighter line height -> visually higher
              ),
            ),
            const SizedBox(height: 8), // was 8

            const Text(
              'Make sure you’ve saved your work or completed any ongoing tasks before logging out.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 2), // was 16

            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Log Out',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
