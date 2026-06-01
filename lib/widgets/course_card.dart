import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;
  final Map<String, int>? progress;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalQuestions = progress?['total'] ?? 0;
    final answered = (progress?['correct'] ?? 0) + (progress?['wrong'] ?? 0);
    final correct = progress?['correct'] ?? 0;

    return Opacity(
      opacity: course.isLocked ? 0.6 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: course.isLocked
                      ? AppColors.lock.withOpacity(0.2)
                      : AppColors.primaryGradientStart.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  course.isLocked ? Icons.lock : Icons.menu_book_rounded,
                  color: course.isLocked ? AppColors.lock : AppColors.primaryGradientStart,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: AppTextStyles.heading2.copyWith(
                        color: course.isLocked ? AppColors.lock : theme.colorScheme.onSurface,
                        fontSize: 15,
                      ),
                    ),
                    if (!course.isLocked && totalQuestions > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: totalQuestions > 0 ? answered / totalQuestions : 0,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.correct),
                                minHeight: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(totalQuestions > 0 ? answered / totalQuestions * 100 : 0).round()}%',
                            style: TextStyle(fontSize: 12, color: AppColors.correct),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$answered/$totalQuestions answered   $correct correct',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ],
                ),
              ),
              if (course.isLocked)
                const Icon(Icons.lock, color: AppColors.lock)
              else
                const Icon(Icons.arrow_forward_ios, color: AppColors.primaryGradientStart, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}