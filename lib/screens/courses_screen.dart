import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/course_card.dart';

final List<Course> _allCourses = const [
  // ---------- Computer Science (id: '1') ----------
  Course(id: '1', departmentId: '1', name: 'Data Structures', isLocked: false),
  Course(id: '2', departmentId: '1', name: 'Algorithms', isLocked: true),
  Course(id: '3', departmentId: '1', name: 'Operating Systems', isLocked: false),

  // ---------- Information Technology (id: '2') ----------
  Course(id: '4', departmentId: '2', name: 'Computer Maintenance and Technical Support', isLocked: false),
  Course(id: '5', departmentId: '2', name: 'Object-Oriented Programming (Java)', isLocked: false),
  Course(id: '6', departmentId: '2', name: 'Advanced Programming', isLocked: false),
  Course(id: '7', departmentId: '2', name: 'Event-Driven Programming', isLocked: false),
  Course(id: '8', departmentId: '2', name: 'System Analysis and Design', isLocked: true),
  Course(id: '9', departmentId: '2', name: 'IT Project Management', isLocked: true),
  Course(id: '10', departmentId: '2', name: 'Fundamentals of Database Systems', isLocked: false),
  Course(id: '11', departmentId: '2', name: 'Advanced Database Systems', isLocked: false),
  Course(id: '12', departmentId: '2', name: 'Internet Programming I', isLocked: false),
  Course(id: '13', departmentId: '2', name: 'Internet Programming II', isLocked: true),
  Course(id: '14', departmentId: '2', name: 'Mobile Application Development', isLocked: false),
  Course(id: '15', departmentId: '2', name: 'Data Communications and Computer Networks', isLocked: false),
  Course(id: '16', departmentId: '2', name: 'System and Network Administration', isLocked: false),
  Course(id: '17', departmentId: '2', name: 'Network Device and Configuration', isLocked: false),
  Course(id: '18', departmentId: '2', name: 'Information Assurance and Security', isLocked: false),

  // ---------- Information Science (id: '3') ----------
  Course(id: '19', departmentId: '3', name: 'Database Management', isLocked: false),
  Course(id: '20', departmentId: '3', name: 'Web Technologies', isLocked: true),

  // ---------- Software Engineering (id: '4') ----------
  Course(id: '21', departmentId: '4', name: 'Software Requirements', isLocked: false),
  Course(id: '22', departmentId: '4', name: 'Software Design', isLocked: false),
  Course(id: '23', departmentId: '4', name: 'Testing & QA', isLocked: true),
];

class CoursesScreen extends StatelessWidget {
  final String departmentId;
  const CoursesScreen({super.key, required this.departmentId});

  @override
  Widget build(BuildContext context) {
    final courses = _allCourses.where((c) => c.departmentId == departmentId).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: courses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final course = courses[index];
          return CourseCard(
            course: course,
            onTap: course.isLocked
                ? null
                : () => context.push(
                      '/exam/${course.id}?courseName=${Uri.encodeComponent(course.name)}',
                    ),
          );
        },
      ),
    );
  }
}