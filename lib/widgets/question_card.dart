import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final int questionNumber;
  final int? selectedIndex;
  final bool isSubmitted;
  final ValueChanged<int> onOptionSelected;

  const QuestionCard({
    super.key,
    required this.question,
    this.questionNumber = 1,
    required this.selectedIndex,
    required this.isSubmitted,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number + text (smaller font)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$questionNumber. ',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.primaryGradientStart,
                    fontSize: 16,
                  ),
                ),
                Expanded(
                  child: Text(
                    question.text,
                    style: AppTextStyles.heading2.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Options
            ...List.generate(question.options.length, (index) {
              final isSelected = selectedIndex == index;
              final isCorrect = index == question.correctIndex;
              final showResult = isSubmitted;

              Color? bgColor;
              if (showResult) {
                if (isCorrect) {
                  bgColor = AppColors.correct.withOpacity(0.2);
                } else if (isSelected && !isCorrect) {
                  bgColor = AppColors.wrong.withOpacity(0.2);
                }
              } else if (isSelected) {
                bgColor = AppColors.primaryGradientStart.withOpacity(0.1);
              }

              return GestureDetector(
                onTap: showResult ? null : () => onOptionSelected(index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: bgColor ?? (theme.brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: showResult && isCorrect
                          ? AppColors.correct
                          : showResult && isSelected && !isCorrect
                              ? AppColors.wrong
                              : isSelected && !showResult
                                  ? AppColors.primaryGradientStart
                                  : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        showResult
                            ? (isCorrect
                                ? Icons.check_circle
                                : (isSelected ? Icons.cancel : Icons.radio_button_off))
                            : (isSelected ? Icons.radio_button_checked : Icons.radio_button_off),
                        color: showResult && isCorrect
                            ? AppColors.correct
                            : showResult && isSelected && !isCorrect
                                ? AppColors.wrong
                                : isSelected
                                    ? AppColors.primaryGradientStart
                                    : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          question.options[index],
                          style: AppTextStyles.body.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: showResult && isCorrect
                                ? AppColors.correct
                                : showResult && isSelected && !isCorrect
                                    ? AppColors.wrong
                                    : theme.colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            // Explanation (shown after answer selection)
            if (isSubmitted)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGradientStart.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryGradientStart.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explanation',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.primaryGradientStart,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question.explanation,
                      style: AppTextStyles.body.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
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
}