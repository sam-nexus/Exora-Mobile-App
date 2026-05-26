import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/auth_text_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Edit Profile form
  final _profileFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _profileLoading = false;
  String? _profileError;
  String? _profileSuccess;

  // Change Password form
  final _passwordFormKey = GlobalKey<FormState>();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmNewPassCtrl = TextEditingController();
  bool _passwordLoading = false;
  String? _passwordError;
  String? _passwordSuccess;

  @override
  void initState() {
    super.initState();
    _loadCachedProfile();
  }

  Future<void> _loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameCtrl.text = prefs.getString('userName') ?? '';
      _emailCtrl.text = prefs.getString('userEmail') ?? '';
    });
  }

  // ------------- Edit Profile -------------
  Future<void> _updateProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() {
      _profileLoading = true;
      _profileError = null;
      _profileSuccess = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      if (userId.isEmpty) throw Exception('User not logged in');

      await ApiService.updateProfile(userId, _nameCtrl.text.trim());

      // Update local cache
      await prefs.setString('userName', _nameCtrl.text.trim());

      setState(() {
        _profileSuccess = 'Profile updated successfully.';
        _profileLoading = false;
      });
    } on SocketException {
      setState(() {
        _profileError = 'No internet connection.';
        _profileLoading = false;
      });
    } on http.ClientException {
      setState(() {
        _profileError = 'Could not reach the server.';
        _profileLoading = false;
      });
    } catch (e) {
      setState(() {
        _profileError = 'Something went wrong. Please try again.';
        _profileLoading = false;
      });
    }
  }

  // ------------- Change Password -------------
  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _passwordLoading = true;
      _passwordError = null;
      _passwordSuccess = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('userEmail') ?? '';
      if (email.isEmpty) throw Exception('User email not found');

      await ApiService.changePassword(
        email,
        _oldPassCtrl.text,
        _newPassCtrl.text,
      );

      // Clear password fields
      _oldPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmNewPassCtrl.clear();

      setState(() {
        _passwordSuccess = 'Password updated successfully.';
        _passwordLoading = false;
      });
    } on SocketException {
      setState(() {
        _passwordError = 'No internet connection.';
        _passwordLoading = false;
      });
    } on http.ClientException {
      setState(() {
        _passwordError = 'Could not reach the server.';
        _passwordLoading = false;
      });
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('incorrect')) {
        setState(() => _passwordError = 'Current password is incorrect.');
      } else {
        setState(() => _passwordError = 'Something went wrong. Please try again.');
      }
      setState(() => _passwordLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmNewPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Edit Profile Section ----------
            _buildSectionTitle('Edit Profile', onSurface),
            const SizedBox(height: 16),
            Form(
              key: _profileFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    controller: _nameCtrl,
                    hint: 'Full Name',
                    prefixIcon: Icons.person_outline,
                    validator: (v) => v!.isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _emailCtrl,
                    hint: 'Email',
                    prefixIcon: Icons.email_outlined,
                    readOnly: true,   // email is not editable
                    validator: null,
                  ),
                  const SizedBox(height: 12),
                  if (_profileError != null) _buildErrorBanner(_profileError!),
                  if (_profileSuccess != null) _buildSuccessBanner(_profileSuccess!),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _profileLoading ? null : _updateProfile,
                    child: _profileLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),

            // ---------- Change Password Section ----------
            _buildSectionTitle('Change Password', onSurface),
            const SizedBox(height: 16),
            Form(
              key: _passwordFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    controller: _oldPassCtrl,
                    hint: 'Current Password',
                    prefixIcon: Icons.lock_outline,
                    obscure: true,
                    validator: (v) => v!.isEmpty ? 'Enter current password' : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _newPassCtrl,
                    hint: 'New Password',
                    prefixIcon: Icons.lock_open,
                    obscure: true,
                    validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _confirmNewPassCtrl,
                    hint: 'Confirm New Password',
                    prefixIcon: Icons.lock_open,
                    obscure: true,
                    validator: (v) => v != _newPassCtrl.text ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: 12),
                  if (_passwordError != null) _buildErrorBanner(_passwordError!),
                  if (_passwordSuccess != null) _buildSuccessBanner(_passwordSuccess!),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _passwordLoading ? null : _changePassword,
                    child: _passwordLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Update Password'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: AppTextStyles.heading2.copyWith(color: color),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade700, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.green.shade700, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}