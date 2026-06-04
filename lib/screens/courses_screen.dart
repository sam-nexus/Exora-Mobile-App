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
  final String contentType; // 'materials' or 'questions'
  final String? courseType; // 'regular', 'mock', 'exit'
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
  Map<String, bool> _downloadedMap = {};

  String get _cacheKey => 'courses_cache_${widget.departmentId}_${widget.courseType ?? widget.contentType}';

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadAllProgress();
    _loadDownloadedStatus();
  }

  Future<void> _loadDownloadedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, bool>{};
    for (final course in _courses) {
      final key = 'downloaded_materials_${course.id}';
      final data = prefs.getString(key);
      map[course.id] = data != null && data.isNotEmpty;
    }
    setState(() => _downloadedMap = map);
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
      final deptCourses = await ApiService.getCourses(widget.departmentId, type: widget.courseType);
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
        _loadDownloadedStatus();
      }
    } on SocketException {
      if (_courses.isEmpty) {
        setState(() => _error = 'No internet connection.');
      } else {
        setState(() => _error = 'You are offline. Showing cached data.');
      }
      setState(() => _loading = false);
    } on http.ClientException {
      if (_courses.isEmpty) {
        setState(() => _error = 'Could not reach the server.');
      } else {
        setState(() => _error = 'Server unreachable. Showing cached data.');
      }
      setState(() => _loading = false);
    } catch (e) {
      if (_courses.isEmpty) {
        setState(() => _error = 'Something went wrong. Tap to retry.');
      } else {
        setState(() => _error = 'Could not refresh. Showing cached data.');
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _onRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    _loadAllProgress();
    _loadDownloadedStatus();
    setState(() {
      _error = null;
      _loading = _courses.isEmpty;
    });
    await _fetchFreshCourses();
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.contentType == 'materials' ? 'Course Materials' : 'Course Questions';
    if (widget.courseType == 'mock') title = 'Mock Exams';
    if (widget.courseType == 'exit') title = 'Exit Exams';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                    child: Text(_error!, style: TextStyle(
                      color: (_fromCache || _courses.isNotEmpty) ? Colors.orange.shade700 : Colors.red.shade700,
                      fontSize: 14,
                    )),
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
                              Text('No courses available.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
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
                    padding: const EdgeInsets.all(20),
                    itemCount: _courses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final course = _courses[index];
                      return CourseCard(
                        course: course,
                        showDownloadIcon: widget.contentType == 'materials',
                        isDownloaded: _downloadedMap[course.id] ?? false,
                        onTap: course.isLocked
                            ? () => context.push('/payment')
                            : () {
                                if (widget.contentType == 'materials') {
                                  context.push('/materials/${course.id}?courseName=${Uri.encodeComponent(course.name)}');
                                } else {
                                  context.push('/exam/${course.id}?courseName=${Uri.encodeComponent(course.name)}&type=course');
                                }
                              },
                        onDownload: widget.contentType == 'materials'
                            ? () async {
                                setState(() => _downloadedMap[course.id] = true);
                                context.push('/materials/${course.id}?courseName=${Uri.encodeComponent(course.name)}');
                              }
                            : null,
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