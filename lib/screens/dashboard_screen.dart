import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';
import '../widgets/greeting_header.dart';

final List<Department> _departments = const [
  Department(id: '1', name: 'Computer Science', icon: '💻'),
  Department(id: '2', name: 'Information Technology', icon: '📡'),
  Department(id: '3', name: 'Information Science', icon: '📚'),
  Department(id: '4', name: 'Software Engineering', icon: '⚙️'),
];

final List<String> _studyTips = const [
  'Break down your study sessions into 25‑minute focused intervals.',
  'Teach what you’ve learned to someone else — it reinforces understanding.',
  'Use active recall: test yourself instead of re‑reading notes.',
  'Prioritise past exam questions and model exams.',
  'Take regular breaks to improve concentration and retention.',
];

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Compute department grid height based on 2 columns, aspect ratio 1.1
    const horizontalPadding = 24.0 * 2; // left + right
    const crossAxisSpacing = 16.0;
    const mainAxisSpacing = 16.0;
    const childAspectRatio = 1.1;
    final itemWidth = (screenWidth - horizontalPadding - crossAxisSpacing) / 2;
    final itemHeight = itemWidth * childAspectRatio;
    final gridHeight = itemHeight * 2 + mainAxisSpacing; // 2 rows

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.school_rounded,
              color: AppColors.primaryGradientStart,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'Exora',
              style: AppTextStyles.heading2.copyWith(
                color: theme.textTheme.headlineMedium?.color,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  context.push('/settings');
                  break;
                case 'about':
                  context.push('/about');
                  break;
                case 'theme':
                  ref.read(themeModeProvider.notifier).toggle();
                  break;
                case 'logout':
                  context.go('/login');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'theme',
                child: Consumer(
                  builder: (context, ref, _) {
                    final mode = ref.watch(themeModeProvider);
                    final isDark = mode == ThemeMode.dark;
                    return ListTile(
                      leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                      title: Text(isDark ? 'Light Mode' : 'Dark Mode'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Greeting Header
              const GreetingHeader(),

              // Department Grid – fixed height, centred
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Department',
                    style: AppTextStyles.heading2.copyWith(
                      color: theme.textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: gridHeight,
                    child: GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: mainAxisSpacing,
                      crossAxisSpacing: crossAxisSpacing,
                      childAspectRatio: childAspectRatio,
                      children: _departments
                          .map((dept) => _DepartmentGridCard(
                                department: dept,
                                onTap: () => context.push('/courses/${dept.id}'),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),

              // Study Tips – horizontal scrollable cards
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Study Tips',
                    style: AppTextStyles.heading2.copyWith(
                      color: theme.textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _studyTips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        return _StudyTipCard(tip: _studyTips[index]);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentGridCard extends StatelessWidget {
  final Department department;
  final VoidCallback onTap;
  const _DepartmentGridCard({required this.department, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryGradientStart.withOpacity(0.15),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(department.icon, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                department.name,
                textAlign: TextAlign.center,
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 15,
                  color: theme.textTheme.headlineMedium?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyTipCard extends StatelessWidget {
  final String tip;
  const _StudyTipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: AppColors.primaryGradientStart,
            size: 24,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              tip,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                height: 1.4,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}