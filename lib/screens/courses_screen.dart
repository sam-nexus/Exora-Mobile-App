import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../theme.dart';
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
  // Now stores: { courseId: { 'correct': int, 'wrong': int, 'total': int } }
  Map<String, Map<String, int>> _progressMap = {};

  String get _cacheKey => 'courses_cache_${widget.departmentId}';

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadAllProgress();
  }

  Future<void> _loadAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('progress_'));
    final map = <String, Map<String, int>>{};
    for (final key in keys) {
      final data = prefs.getString(key);
      if (data != null) {
        final courseId = key.substring('progress_'.length);
        final json = jsonDecode(data) as Map<String, dynamic>;
        map[courseId] = {
          'correct': json['correct'] ?? 0,
          'wrong': json['wrong'] ?? 0,
          'total': json['total'] ?? 0,   // NEW
        };
      }
    }
    setState(() => _progressMap = map);
  }

  Future<void> _loadCourses() async {
    final cached = await _loadFromCache();
    if (cached != null) {
      setState(() {
        _courses = cached;
        _loading = false;
        _fromCache = true;
      });
    }
    await _fetchFreshCourses();
  }

  Future<List<Course>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString == null) return null;
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((c) => Course(
        id: c['id'],
        departmentId: widget.departmentId,
        name: c['name'],
        isLocked: c['isLocked'] ?? true,
      )).toList();
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

  Future<void> _fetchFreshCourses() async {
    try {
      final deptCourses = await ApiService.getCourses(widget.departmentId);
      final userCourses = await ApiService.getUserCourses();

      final lockMap = <String, bool>{};
      for (var uc in userCourses) {
        lockMap[uc['course_id']] = uc['is_locked'];
      }

      final courses = deptCourses
          .map((c) => Course(
                id: c['id'],
                departmentId: widget.departmentId,
                name: c['name'],
                isLocked: lockMap[c['id']] ?? true,
              ))
          .toList();

      final cacheData = deptCourses.map((c) => {
        'id': c['id'],
        'name': c['name'],
        'isLocked': lockMap[c['id']] ?? true,
      }).toList();
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
      if (_courses.isEmpty) {
        setState(() {
          _error = 'No internet connection.';
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'You are offline. Showing cached data.';
          _loading = false;
        });
      }
    } on http.ClientException {
      if (_courses.isEmpty) {
        setState(() {
          _error = 'Could not reach the server.';
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Server unreachable. Showing cached data.';
          _loading = false;
        });
      }
    } catch (e) {
      if (_courses.isEmpty) {
        setState(() {
          _error = 'Something went wrong. Tap to retry.';
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    _loadAllProgress();
    setState(() {
      _error = null;
      _loading = _courses.isEmpty;
    });
    await _fetchFreshCourses();
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
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              decoration: BoxDecoration(
                color: (_fromCache || _courses.isNotEmpty) ? Colors.orange.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (_fromCache || _courses.isNotEmpty) ? Colors.orange.shade200 : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    (_fromCache || _courses.isNotEmpty) ? Icons.wifi_off : Icons.error_outline,
                    color: (_fromCache || _courses.isNotEmpty) ? Colors.orange.shade700 : Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: (_fromCache || _courses.isNotEmpty) ? Colors.orange.shade700 : Colors.red.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _courses.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.book_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No courses available.',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
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
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, index) {
                      final course = _courses[index];
                      return CourseCard(
                        course: course,
                        onTap: course.isLocked
                            ? () => context.push('/payment')
                            : () => context.push(
                                '/exam/${course.id}?courseName=${Uri.encodeComponent(course.name)}',
                              ),
                        progress: _progressMap[course.id],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}