import 'package:exora/screens/notifications_screen.dart';
import 'package:go_router/go_router.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/exam_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    GoRoute(
      path: '/courses/:departmentId',
      builder: (_, state) => CoursesScreen(
        departmentId: state.pathParameters['departmentId']!,
      ),
    ),
    GoRoute(
      path: '/exam/:courseId',
      builder: (_, state) {
        final courseId = state.pathParameters['courseId']!;
        final courseName = state.uri.queryParameters['courseName'];
        return ExamScreen(courseId: courseId, courseName: courseName);
      },
    ),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
  ],
);