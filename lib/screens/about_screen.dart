import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.grey.shade800;
    final subtitleColor = theme.textTheme.bodyLarge?.color?.withOpacity(0.7) ?? Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Exora'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryGradientStart.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 56,
                color: AppColors.primaryGradientStart,
              ),
            ),
            const SizedBox(height: 24),
            // App name
            Text(
              'Exora',
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.primaryGradientStart,
                fontSize: 36,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Ultimate Exit Exam Preparation Companion',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading2.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // Description section
            _buildSection(
              title: 'What is Exora?',
              content: 'Exora is a comprehensive mobile platform designed to help final‑year university students prepare for their exit exams. '
                  'We provide a vast collection of past exit exams, model exams with detailed answer explanations, and a personalised learning experience '
                  'that adapts to your department and course needs.',
              titleColor: textColor,
              textColor: subtitleColor,
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Key Features',
              content: '• Access past exit exams and model exams\n'
                  '• Department‑specific courses with lock/unlock control\n'
                  '• Multiple‑choice questions with instant feedback and explanations\n'
                  '• Secure payment verification to unlock premium content\n'
                  '• Admin dashboard for content management and user oversight',
              titleColor: textColor,
              textColor: subtitleColor,
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'How It Works',
              content: '1. Create an account and select your department.\n'
                  '2. Unlock your courses by submitting a payment receipt.\n'
                  '3. Practice with model exams and track your progress.\n'
                  '4. Review detailed explanations to strengthen your understanding.',
              titleColor: textColor,
              textColor: subtitleColor,
            ),
            const SizedBox(height: 16),

            // Version info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGradientStart.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryGradientStart.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  Text(
                    'Version 1.0.0',
                    style: AppTextStyles.body.copyWith(color: AppColors.primaryGradientStart, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Developed with ❤️ for students',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: subtitleColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Error handling placeholder – if we ever fetch version/status from backend,
            // we could show a retry button here. For now it’s static.
            // The SingleChildScrollView ensures everything is reachable on smaller screens.
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required Color titleColor,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(color: titleColor),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: AppTextStyles.body.copyWith(color: textColor, height: 1.5),
        ),
      ],
    );
  }
}