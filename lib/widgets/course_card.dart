import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;

  const CourseCard({super.key, required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: course.isLocked ? 0.6 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: course.isLocked
                      ? AppColors.lock.withOpacity(0.2)
                      : AppColors.primaryGradientStart.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  course.isLocked ? Icons.lock : Icons.menu_book_rounded,
                  color: course.isLocked ? AppColors.lock : AppColors.primaryGradientStart,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  course.name,
                  style: AppTextStyles.heading2.copyWith(
                    color: course.isLocked ? AppColors.lock : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (course.isLocked)
                const Icon(Icons.lock, color: AppColors.lock)
              else
                const Icon(Icons.arrow_forward_ios, color: AppColors.primaryGradientStart, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}