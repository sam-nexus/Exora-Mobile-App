import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models.dart';
import '../theme.dart';

class DepartmentSearch extends StatelessWidget {
  final List<Department> departments;
  const DepartmentSearch({super.key, required this.departments});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Department', style: AppTextStyles.heading2.copyWith(
          color: theme.textTheme.headlineMedium?.color,
        )),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'Search department...',
              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              suffixIcon: PopupMenuButton<Department>(
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryGradientStart),
                onSelected: (dept) => context.go('/courses/${dept.id}'),
                itemBuilder: (context) => departments
                    .map((dept) => PopupMenuItem(
                          value: dept,
                          child: Row(
                            children: [
                              Text(dept.icon, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Text(dept.name, style: TextStyle(color: theme.colorScheme.onSurface)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }
}