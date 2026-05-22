import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../widgets/auth_text_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmNewPassCtrl = TextEditingController();

  void _changePassword() {
    if (_formKey.currentState!.validate()) {
      // Mock success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );
      context.pop();
    }
  }

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmNewPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Change Password', style: AppTextStyles.heading2.copyWith(
                color: theme.textTheme.headlineMedium?.color,
              )),
              const SizedBox(height: 24),
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _changePassword,
                  child: const Text('Update Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}