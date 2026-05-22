import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Exora'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_rounded, size: 80, color: AppColors.primaryGradientStart),
              const SizedBox(height: 24),
              Text(
                'Exora',
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.primaryGradientStart,
                  fontSize: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your ultimate exit exam preparation companion.\n\nVersion 1.0.0\nDeveloped with ❤️ for students.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: theme.textTheme.bodyLarge?.color,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}