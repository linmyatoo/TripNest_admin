import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_storage.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';

class ChangePasswordPage extends StatefulWidget {
  static const route = '/change-password';
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _apiService = ApiService();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    final currentPassword = _currentPasswordCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    // Validation
    if (currentPassword.isEmpty) {
      _showSnackBar('Please enter your current password', isError: true);
      return;
    }
    if (newPassword.isEmpty) {
      _showSnackBar('Please enter your new password', isError: true);
      return;
    }
    if (newPassword.length < 6) {
      _showSnackBar('New password must be at least 6 characters',
          isError: true);
      return;
    }
    if (confirmPassword.isEmpty) {
      _showSnackBar('Please confirm your new password', isError: true);
      return;
    }
    if (newPassword != confirmPassword) {
      _showSnackBar('New passwords do not match', isError: true);
      return;
    }
    if (currentPassword == newPassword) {
      _showSnackBar('New password must be different from current password',
          isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.changePassword(
        oldPassword: currentPassword,
        newPassword: newPassword,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        // Clear auth and navigate to login
        await AuthStorage.clearAuth();

        if (mounted) {
          _showSnackBar('Password changed successfully. Please login again.');
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (_) => false,
          );
        }
      } else {
        _showSnackBar(result['message'] ?? 'Failed to change password',
            isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('An error occurred. Please try again.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: const BackButton(), title: const Text('Change Password')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text('Current Password',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          AppTextField(
            hint: 'Enter your current password',
            obscure: _obscureCurrent,
            controller: _currentPasswordCtrl,
            prefix: const Icon(Icons.lock_outline),
            suffix: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Icon(
                  _obscureCurrent
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('New Password',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          AppTextField(
            hint: 'Enter your new password',
            obscure: _obscureNew,
            controller: _newPasswordCtrl,
            prefix: const Icon(Icons.lock_outline),
            suffix: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Icon(
                  _obscureNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Confirm New Password',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          AppTextField(
            hint: 'Confirm your new password',
            obscure: _obscureConfirm,
            controller: _confirmPasswordCtrl,
            prefix: const Icon(Icons.lock_outline),
            suffix: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: _isLoading ? 'Saving...' : 'Save Changes',
            onPressed: _isLoading ? null : _handleChangePassword,
          ),
        ],
      ),
    );
  }
}
