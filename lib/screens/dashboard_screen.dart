import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/greeting_header.dart';
import '../widgets/quote_carousel.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  List<Department> _departments = [];
  bool _loading = true;
  String? _error;

  final List<String> _quotes = [
    "“The expert in anything was once a beginner.”",
    "“Success is no accident.”",
    "“Don’t watch the clock; do what it does.”",
    "“Believe you can and you’re halfway there.”",
  ];

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    try {
      final data = await ApiService.getDepartments();
      setState(() {
        _departments = data.map((d) => Department(
          id: d['id'],
          name: d['name'],
          icon: d['icon'] ?? '📁',
        )).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_rounded, color: AppColors.primaryGradientStart, size: 28),
            const SizedBox(width: 8),
            Text('Exora', style: AppTextStyles.heading2.copyWith(color: theme.textTheme.headlineMedium?.color)),
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
              if (value == 'logout') {
                context.go('/login');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const GreetingHeader(),
                        const SizedBox(height: 28),
                        Text('Select Department', style: AppTextStyles.heading2.copyWith(color: theme.textTheme.headlineMedium?.color)),
                        const SizedBox(height: 12),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.1,
                            ),
                            itemCount: _departments.length,
                            itemBuilder: (_, index) => _DepartmentCard(
                              department: _departments[index],
                              onTap: () => context.push('/courses/${_departments[index].id}'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Study Tips', style: AppTextStyles.heading2.copyWith(color: theme.textTheme.headlineMedium?.color)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 130,
                          child: QuoteCarousel(quotes: _quotes),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  final Department department;
  final VoidCallback onTap;
  const _DepartmentCard({required this.department, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGradientStart.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(department.icon, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(department.name, textAlign: TextAlign.center, style: AppTextStyles.heading2.copyWith(fontSize: 15, color: theme.textTheme.headlineMedium?.color)),
            ),
          ],
        ),
      ),
    );
  }
}