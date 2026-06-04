import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:exora/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets/greeting_header.dart';

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
  int _unreadNotifications = 0;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  int _currentBanner = 0;
  Timer? _bannerTimer;

  int _currentTip = 0;
  Timer? _tipTimer;

  final List<Map<String, dynamic>> _banners = const [
    {
      'icon': Icons.workspace_premium,
      'title': 'Go Premium',
      'subtitle': 'Unlock all courses & features',
      'gradient': [Color(0xFFFFD700), Color(0xFFFFA500)],
      'type': 'premium',
    },
    {
      'icon': Icons.send,
      'title': 'Join Telegram',
      'subtitle': 'Get support & latest updates',
      'gradient': [Color(0xFF0088CC), Color(0xFF006699)],
      'type': 'telegram',
    },
  ];

  final List<Map<String, dynamic>> _studyTips = const [
    {
      'icon': Icons.timer,
      'title': 'Pomodoro Technique',
      'subtitle': 'Study 25 min, break 5 min',
      'detail': 'Improves focus and prevents burnout.',
      'gradient': [Color(0xFF6C63FF), Color(0xFF3F3D9E)],
    },
    {
      'icon': Icons.psychology,
      'title': 'Active Recall',
      'subtitle': 'Test yourself, don\'t re‑read',
      'detail': 'Boosts long‑term memory retention.',
      'gradient': [Color(0xFFFF6584), Color(0xFFFF3D5A)],
    },
    {
      'icon': Icons.group,
      'title': 'Teach Others',
      'subtitle': 'Explain concepts aloud',
      'detail': 'Reinforces your own understanding.',
      'gradient': [Color(0xFF00BFA5), Color(0xFF009688)],
    },
    {
      'icon': Icons.bedtime,
      'title': 'Sleep Well',
      'subtitle': 'Rest improves memory',
      'detail': 'Aim for 7‑8 hours each night.',
      'gradient': [Color(0xFFFFA726), Color(0xFFFB8C00)],
    },
    {
      'icon': Icons.water_drop,
      'title': 'Stay Hydrated',
      'subtitle': 'Water keeps your brain sharp',
      'detail': 'Dehydration reduces concentration.',
      'gradient': [Color(0xFF42A5F5), Color(0xFF1E88E5)],
    },
  ];

  static const String _cacheKey = 'departments_cache';

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _startBannerTimer();
    _startTipTimer();
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _tipTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationService.getUnreadCount();
    if (mounted) setState(() => _unreadNotifications = count);
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() => _currentBanner = (_currentBanner + 1) % _banners.length);
      }
    });
  }

  void _startTipTimer() {
    _tipTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) {
        setState(() => _currentTip = (_currentTip + 1) % _studyTips.length);
      }
    });
  }

  void _onBannerTap(String type) {
    if (type == 'premium') {
      context.push('/payment');
    } else if (type == 'telegram') {
      launchUrl(Uri.parse('https://t.me/YOUR_GROUP_USERNAME'));
    }
  }

  List<Department> get _filteredDepartments {
    if (_searchQuery.isEmpty) return _departments;
    return _departments
        .where((d) => d.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _loadDepartments() async {
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
      return list
          .map(
            (d) => Department(
              id: d['id'],
              name: d['name'],
              icon: d['icon'] ?? '📁',
            ),
          )
          .toList();
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
      final data = await ApiService.getDepartments();
      final departments = data
          .map(
            (d) => Department(
              id: d['id'],
              name: d['name'],
              icon: d['icon'] ?? '📁',
            ),
          )
          .toList();
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
      if (_departments.isEmpty) {
        setState(() => _error = 'No internet connection.');
      } else {
        setState(() => _error = 'You are offline. Showing cached data.');
      }
      setState(() => _loading = false);
    } on http.ClientException {
      if (_departments.isEmpty) {
        setState(() => _error = 'Could not reach the server.');
      } else {
        setState(() => _error = 'Server unreachable. Showing cached data.');
      }
      setState(() => _loading = false);
    } catch (e) {
      if (_departments.isEmpty) {
        setState(() => _error = 'Something went wrong.');
      } else {
        setState(() => _error = 'Could not refresh. Showing cached data.');
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.school_rounded,
                  color: AppColors.primaryGradientStart,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Exora',
              style: AppTextStyles.heading2.copyWith(
                color: theme.textTheme.headlineMedium?.color,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () async {
                  await context.push('/notifications');
                  _loadUnreadCount(); // refresh badge after viewing notifications
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$_unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {
              if (value == 'settings') {
                context.push('/settings');
              } else if (value == 'about')
                context.push('/about');
              else if (value == 'theme')
                ref.read(themeModeProvider.notifier).toggle();
              else if (value == 'logout') {
                ref.read(authStateProvider.notifier).logout();
                context.go('/login');
              }
            },
            itemBuilder: (ctx) => [
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
                  builder: (c, ref, _) => ListTile(
                    leading: Icon(
                      ref.watch(themeModeProvider) == ThemeMode.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                    ),
                    title: Text(
                      ref.watch(themeModeProvider) == ThemeMode.dark
                          ? 'Light Mode'
                          : 'Dark Mode',
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDepartments,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) _buildErrorBanner(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const GreetingHeader(),
                            const SizedBox(height: 20),
                            _buildSlidingCard(
                              key: ValueKey(_currentBanner),
                              data: _banners[_currentBanner],
                              onTap: () => _onBannerTap(
                                _banners[_currentBanner]['type'] as String,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Select Department',
                              style: AppTextStyles.heading2.copyWith(
                                color: theme.textTheme.headlineMedium?.color,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _searchCtrl,
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                              decoration: InputDecoration(
                                hintText: 'Search departments...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: AppColors.primaryGradientStart,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _filteredDepartments.isEmpty
                            ? SizedBox(
                                height: 200,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.school_outlined,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'No match.'
                                            : 'No departments.',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _loading = true;
                                            _error = null;
                                          });
                                          _loadDepartments();
                                        },
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 0.85,
                                    ),
                                itemCount: _filteredDepartments.length,
                                itemBuilder: (_, i) =>
                                    _buildDeptCard(_filteredDepartments[i]),
                              ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Study Tips & Advice',
                          style: AppTextStyles.heading2.copyWith(
                            color: theme.textTheme.headlineMedium?.color,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSlidingCard(
                          key: ValueKey(_currentTip),
                          data: _studyTips[_currentTip],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSlidingCard({
    required Key key,
    required Map<String, dynamic> data,
    VoidCallback? onTap,
  }) {
    final colors = data['gradient'] as List<Color>;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Container(
          key: key,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data['icon'] as IconData,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['subtitle'] as String,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 12,
                      ),
                    ),
                    if (data['detail'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        data['detail'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeptCard(Department dept) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.push(
        '/content-menu/${dept.id}?name=${Uri.encodeComponent(dept.name)}',
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.06),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(dept.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                dept.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    final isWarning = _fromCache || _departments.isNotEmpty;
    final color = isWarning ? Colors.orange : Colors.red;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isWarning ? Icons.wifi_off : Icons.error_outline,
            color: color.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: color.shade700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
