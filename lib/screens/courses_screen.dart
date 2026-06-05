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
  final String contentType; // 'materials' or 'questions'
  final String? courseType; // null = regular, 'mock', 'exit'
  const CoursesScreen({
    super.key,
    required this.departmentId,
    required this.contentType,
    this.courseType,
  });

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Course> _courses = [];
  bool _loading = true;
  String? _error;
  bool _fromCache = false;
  Map<String, Map<String, int>> _progressMap = {};

  String get _cacheKey => 'courses_cache_${widget.departmentId}_${widget.courseType ?? widget.contentType}';

  // Show progress only for questions/exams, not for materials
  bool get _showProgress => widget.contentType == 'questions';

  @override
  void initState() {
    super.initState();
    _loadCourses();
    if (_showProgress) {
      _loadAllProgress();
    }
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
          'total': json['total'] ?? 0,
        };
      }
    }
    if (mounted) setState(() => _progressMap = map);
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
      final type = widget.courseType ?? 'regular';
      final deptCourses = await ApiService.getCourses(widget.departmentId, type: type);
      final userCourses = await ApiService.getUserCourses();

      final lockMap = <String, bool>{};
      for (var uc in userCourses) {
        lockMap[uc['course_id']] = uc['is_locked'];
      }

      final courses = deptCourses.map((c) => Course(
        id: c['id'],
        departmentId: widget.departmentId,
        name: c['name'],
        isLocked: lockMap[c['id']] ?? true,
      )).toList();

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
      _handleNetworkError('No internet connection.');
    } on http.ClientException {
      _handleNetworkError('Could not reach the server.');
    } catch (e) {
      if (_courses.isEmpty) {
        setState(() { _error = 'Something went wrong. Pull down to retry.'; _loading = false; });
      } else {
        setState(() { _error = 'You are offline. Showing cached data.'; _loading = false; });
      }
    }
  }

  void _handleNetworkError(String msg) {
    if (_courses.isEmpty) {
      setState(() { _error = msg; _loading = false; });
    } else {
      setState(() { _error = 'You are offline. Showing cached data.'; _loading = false; });
    }
  }

  Future<void> _onRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    if (_showProgress) _loadAllProgress();
    setState(() { _error = null; _loading = _courses.isEmpty; });
    await _fetchFreshCourses();
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Courses';
    if (widget.contentType == 'materials') title = 'Course Materials';
    if (widget.contentType == 'questions') title = 'Course Questions';
    if (widget.courseType == 'mock') title = 'Mock Exams';
    if (widget.courseType == 'exit') title = 'Exit Exams';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
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
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              decoration: BoxDecoration(
                color: _fromCache ? Colors.orange.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _fromCache ? Colors.orange.shade200 : Colors.red.shade200),
              ),
              child: Row(children: [
                Icon(_fromCache ? Icons.wifi_off : Icons.error_outline, color: _fromCache ? Colors.orange.shade700 : Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: TextStyle(color: _fromCache ? Colors.orange.shade700 : Colors.red.shade700, fontSize: 14))),
              ]),
            ),
          Expanded(
            child: _courses.isEmpty
                ? ListView(children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.6, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.book_outlined, size: 64, color: Colors.grey.shade400), const SizedBox(height: 16),
                      Text('No courses available.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(onPressed: _onRefresh, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                    ]))),
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _courses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final course = _courses[index];
                      return CourseCard(
                        course: course,
                        onTap: course.isLocked
                            ? () => context.push('/payment')
                            : () {
                                if (widget.contentType == 'materials') {
                                  context.push('/materials/${course.id}?courseName=${Uri.encodeComponent(course.name)}');
                                } else {
                                  context.push('/exam/${course.id}?courseName=${Uri.encodeComponent(course.name)}&type=course');
                                }
                              },
                        progress: _showProgress ? _progressMap[course.id] : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}