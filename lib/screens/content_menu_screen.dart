import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class ContentMenuScreen extends StatelessWidget {
  final String departmentId;
  final String departmentName;

  const ContentMenuScreen({
    super.key,
    required this.departmentId,
    required this.departmentName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(departmentName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What would you like to study?',
              style: AppTextStyles.heading2.copyWith(
                color: onSurface,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionCard(
              context,
              icon: Icons.book,
              title: 'Course Materials',
              subtitle: 'Lecture notes, PDFs & references',
              iconColor: const Color(0xFF6C63FF),
              onTap: () =>
                  context.push('/courses/$departmentId?type=materials'),
            ),
            _buildOptionCard(
              context,
              icon: Icons.quiz,
              title: 'Course Questions',
              subtitle: 'Practice questions for each course',
              iconColor: const Color(0xFFFF6584),
              onTap: () =>
                  context.push('/courses/$departmentId?type=questions'),
            ),
            _buildOptionCard(
              context,
              icon: Icons.assignment,
              title: 'Mock Exams',
              subtitle: 'Mock exam simulations',
              iconColor: const Color(0xFF00BFA5),
              onTap: () => context.push(
                '/courses/$departmentId?type=questions&courseType=mock',
              ),
            ),
            _buildOptionCard(
              context,
              icon: Icons.school,
              title: 'Exit Exams',
              subtitle: 'Past exit exam papers',
              iconColor: const Color(0xFFFFA726),
              onTap: () => context.push(
                '/courses/$departmentId?type=questions&courseType=exit',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.heading2.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.body.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
