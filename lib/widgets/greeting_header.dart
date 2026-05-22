import 'package:flutter/material.dart';
import '../theme.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    String greeting = 'Good morning';
    if (hour >= 12 && hour < 17) greeting = 'Good afternoon';
    else if (hour >= 17) greeting = 'Good evening';

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primaryGradientStart.withOpacity(0.15),
          child: const Icon(Icons.person, color: AppColors.primaryGradientStart, size: 32),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: AppTextStyles.body.copyWith(
                color: theme.textTheme.bodyLarge?.color,
              )),
              const SizedBox(height: 4),
              Text('John Doe 👋', style: AppTextStyles.heading2.copyWith(
                color: theme.textTheme.headlineMedium?.color,
              )),
            ],
          ),
        ),
      ],
    );
  }
}