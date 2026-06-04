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
          children: [
            // Logo & Name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGradientStart.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.school_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Exora',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.primaryGradientStart,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Exit Exam Preparation Platform',
                    style: AppTextStyles.body.copyWith(
                      color: subtitleColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // What is Exora? card
            _buildInfoCard(
              context,
              icon: Icons.lightbulb_outline,
              title: 'What is Exora?',
              content: 'A comprehensive platform for final‑year students preparing for exit exams with past papers, model exams, and detailed explanations.',
              iconColor: Colors.amber,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 14),

            // Key Features card
            _buildInfoCard(
              context,
              icon: Icons.star_outline,
              title: 'Key Features',
              content: 'Past exams • Model exams • Instant feedback • Course materials • Progress tracking • Offline access',
              iconColor: Colors.purple,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 14),

            // How It Works card
            _buildInfoCard(
              context,
              icon: Icons.rocket_launch_outlined,
              title: 'How It Works',
              content: 'Register → Unlock courses → Practice → Track your progress → Ace your exams!',
              iconColor: Colors.teal,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 24),

            // Version card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Text(
                    'Version 1.0.0',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primaryGradientStart,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Developed with ❤️ for students',
                    style: AppTextStyles.body.copyWith(
                      color: subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading2.copyWith(
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: AppTextStyles.body.copyWith(
                    color: subtitleColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}