import 'dart:convert';
import 'dart:io';
import 'package:exora/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../providers/auth_provider.dart';
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
  bool _fromCache = false;

  final List<String> _quotes = [
    "“The expert in anything was once a beginner.”",
    "“Success is no accident.”",
    "“Don’t watch the clock; do what it does.”",
    "“Believe you can and you’re halfway there.”",
  ];

  static const String _cacheKey = 'departments_cache';

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    // Load from cache first
    final cached = await _loadFromCache();
    if (cached != null) {
      setState(() {
        _departments = cached;
        _loading = false;
        _fromCache = true;
      });
    }
    await _fetchFreshDepartments();
  }

  Future<List<Department>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString == null) return null;
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((d) => Department(
        id: d['id'],
        name: d['name'],
        icon: d['icon'] ?? '📁',
      )).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _fetchFreshDepartments() async {
    try {
      print('🔍 Fetching departments from ${ApiService.baseUrl}/departments');
      final data = await ApiService.getDepartments();
      print('✅ Received ${data.length} departments');

      final departments = data.map((d) => Department(
        id: d['id'],
        name: d['name'],
        icon: d['icon'] ?? '📁',
      )).toList();

      await _saveToCache(data);

      if (mounted) {
        setState(() {
          _departments = departments;
          _loading = false;
          _fromCache = false;
          _error = null;
        });
      }
    } on SocketException {
      print('❌ No internet');
      if (_departments.isEmpty) {
        setState(() => _error = 'No internet connection. Tap to retry.');
      } else {
        setState(() => _error = 'You are offline. Showing cached data.');
      }
      setState(() => _loading = false);
    } on http.ClientException catch (e) {
      print('❌ ClientException: $e');
      if (_departments.isEmpty) {
        setState(() => _error = 'Could not reach the server. Tap to retry.');
      } else {
        setState(() => _error = 'Server unreachable. Showing cached data.');
      }
      setState(() => _loading = false);
    } catch (e) {
      print('❌ Other error: $e');
      if (_departments.isEmpty) {
        setState(() => _error = 'Something went wrong. Tap to retry.');
      } else {
        setState(() => _error = 'Could not refresh. Showing cached data.');
      }
      setState(() => _loading = false);
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _loadDepartments();
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
              if (value == 'settings') {
                context.push('/settings');
              } else if (value == 'about') {
                context.push('/about');
              } else if (value == 'theme') {
                ref.read(themeModeProvider.notifier).toggle();
              } else if (value == 'logout') {
                ref.read(authStateProvider.notifier).logout();
                context.go('/login');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(leading: Icon(Icons.settings), title: Text('Settings'), dense: true, contentPadding: EdgeInsets.zero),
              ),
              const PopupMenuItem(
                value: 'about',
                child: ListTile(leading: Icon(Icons.info_outline), title: Text('About'), dense: true, contentPadding: EdgeInsets.zero),
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
                child: ListTile(leading: Icon(Icons.logout), title: Text('Logout'), dense: true, contentPadding: EdgeInsets.zero),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadDepartments,
      child: Column(
        children: [
          if (_error != null) _buildErrorBanner(),
          Expanded(
            child: _departments.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('No departments available.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _retry,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
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
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    final isWarning = _fromCache || _departments.isNotEmpty;
    final color = isWarning ? Colors.orange : Colors.red;
    final icon = isWarning ? Icons.wifi_off : Icons.error_outline;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_error!, style: TextStyle(color: color.shade700, fontSize: 14)),
          ),
          if (_departments.isEmpty)
            GestureDetector(
              onTap: _retry,
              child: Icon(Icons.refresh, color: color.shade700, size: 22),
            ),
        ],
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