import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      // Fetch courses for the department (no lock info here)
      final deptCourses = await ApiService.getCourses(widget.departmentId);
      // Fetch user's lock status
      final userCourses = await ApiService.getUserCourses();
      // Build map: course_id -> is_locked
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
              isLocked: lockMap[c['id']] ?? true, // default locked
            ),
          )
          .toList();

      setState(() {
        _courses = courses;
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
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _courses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
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
    );
  }
}
