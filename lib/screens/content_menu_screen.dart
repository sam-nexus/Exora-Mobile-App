import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
            const SizedBox(height: 24),
            _buildOptionCard(
              context,
              icon: Icons.book,
              title: 'Course Materials',
              subtitle: 'Lecture notes, PDFs & references',
              gradient: const [Color(0xFF6C63FF), Color(0xFF3F3D9E)],
              onTap: () =>
                  context.push('/courses/$departmentId?type=materials'),
            ),
            _buildOptionCard(
              context,
              icon: Icons.quiz,
              title: 'Course Questions',
              subtitle: 'Practice questions for each course',
              gradient: const [Color(0xFFFF6584), Color(0xFFFF3D5A)],
              onTap: () =>
                  context.push('/courses/$departmentId?type=questions'),
            ),
            _buildOptionCard(
              context,
              icon: Icons.assignment,
              title: 'Mock Exams',
              subtitle: 'Mock exam simulations',
              gradient: const [Color(0xFF00BFA5), Color(0xFF009688)],
              onTap: () => context.push(
                '/courses/$departmentId?type=questions&courseType=mock',
              ),
            ),
            _buildOptionCard(
              context,
              icon: Icons.school,
              title: 'Exit Exams',
              subtitle: 'Past exit exam papers',
              gradient: const [Color(0xFFFFA726), Color(0xFFFB8C00)],
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
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.3),
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
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
