import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../widgets/course_card.dart';

class CoursesScreen extends StatefulWidget {
  final String departmentId;
  const CoursesScreen({super.key, required this.departmentId});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Course> _courses = [];
  bool _loading = true;
  String? _error;
  bool _fromCache = false;

  String get _cacheKey => 'courses_cache_${widget.departmentId}';

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  /// Attempts to load from cache first, then fetches fresh data.
  Future<void> _loadCourses() async {
    // 1. Load cached courses
    final cached = await _loadFromCache();
    if (cached != null) {
      setState(() {
        _courses = cached;
        _loading = false;
        _fromCache = true;
      });
    }

    // 2. Fetch fresh data (keeps loading indicator if no cache yet)
    await _fetchFreshCourses();
  }

  /// Manually retry fetching (called by pull-to-refresh or retry button).
  // Future<void> _onRefresh() async {
  //   setState(() {
  //     _error = null;
  //     _loading = _courses.isEmpty; // show spinner only if no data at all
  //   });
  //   await _fetchFreshCourses();
  // }

  // --------------- cache helpers -----------------------
  Future<List<Course>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString == null) return null;

      final List<dynamic> list = jsonDecode(jsonString);
      return list
          .map(
            (c) => Course(
              id: c['id'],
              departmentId: widget.departmentId,
              name: c['name'],
              isLocked: c['isLocked'] ?? true,
            ),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(List<dynamic> coursesData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(coursesData));
    } catch (_) {}
  }

  // --------------- network fetch -----------------------
  Future<void> _fetchFreshCourses() async {
    try {
      final deptCourses = await ApiService.getCourses(widget.departmentId);
      final userCourses = await ApiService.getUserCourses();

      final lockMap = <String, bool>{};
      for (var uc in userCourses) {
        lockMap[uc['course_id']] = uc['is_locked'];
      }

      final courses = deptCourses
          .map(
            (c) => Course(
              id: c['id'],
              departmentId: widget.departmentId,
              name: c['name'],
              isLocked: lockMap[c['id']] ?? true,
            ),
          )
          .toList();

      // Save fresh data to cache
      final cacheData = deptCourses
          .map(
            (c) => {
              'id': c['id'],
              'name': c['name'],
              'isLocked': lockMap[c['id']] ?? true,
            },
          )
          .toList();
      await _saveToCache(cacheData);

      if (mounted) {
        setState(() {
          _courses = courses;
          _loading = false;
          _fromCache = false;
          _error = null;
        });
      }
    } on SocketException {
      _handleNetworkError('No internet connection. Pull down to retry.');
    } on http.ClientException {
      _handleNetworkError('Could not reach the server. Pull down to retry.');
    } catch (e) {
      if (_courses.isEmpty) {
        setState(() {
          _error = 'Something went wrong. Pull down to retry.';
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Could not refresh. Showing cached data.';
          _loading = false;
        });
      }
    }
  }


Future<void> _onRefresh() async {
  // Clear the cache so we definitely fetch fresh data
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_cacheKey);

  setState(() {
    _error = null;
    _loading = _courses.isEmpty;
  });
  await _fetchFreshCourses();
}


  void _handleNetworkError(String message) {
    if (_courses.isEmpty) {
      setState(() {
        _error = message;
        _loading = false;
      });
    } else {
      setState(() {
        _error = 'You are offline. Showing cached data.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: Column(
        children: [
          // Error banner
          if (_error != null) _buildErrorBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh, // a new small method
              child: _courses.isEmpty
                  ? ListView(
                      // must be a scrollable for RefreshIndicator to work
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.book_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No courses available.',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _onRefresh,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: _courses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (_, index) {
                        final course = _courses[index];
                        return CourseCard(
                          course: course,
                          onTap: course.isLocked
                              ? () => context.push('/payment')
                              : () => context.push(
                                  '/exam/${course.id}?courseName=${Uri.encodeComponent(course.name)}',
                                ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  

  Widget _buildErrorBanner() {
    final isWarning = _fromCache || _courses.isNotEmpty;
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
