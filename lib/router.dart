import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/content_menu_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/exam_menu_screen.dart';
import 'screens/exam_screen.dart';
import 'screens/materials_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/verify_reset_code_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/support_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (_, _) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/verify-reset-code',
      builder: (_, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return VerifyResetCodeScreen(email: email);
      },
    ),
    GoRoute(
      path: '/reset-password',
      builder: (_, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        final code = state.uri.queryParameters['code'] ?? '';
        return ResetPasswordScreen(email: email, code: code);
      },
    ),
    GoRoute(
      path: '/content-menu/:departmentId',
      builder: (_, state) {
        final departmentId = state.pathParameters['departmentId']!;
        final departmentName =
            state.uri.queryParameters['name'] ?? 'Department';
        return ContentMenuScreen(
          departmentId: departmentId,
          departmentName: departmentName,
        );
      },
    ),
    GoRoute(
      path: '/courses/:departmentId',
      builder: (_, state) {
        final departmentId = state.pathParameters['departmentId']!;
        final contentType = state.uri.queryParameters['type'] ?? 'questions';
        final courseType =
            state.uri.queryParameters['courseType']; // null, 'mock', or 'exit'
        return CoursesScreen(
          departmentId: departmentId,
          contentType: contentType,
          courseType: courseType,
        );
      },
    ),
    GoRoute(
      path: '/exams/:departmentId',
      builder: (_, state) {
        final departmentId = state.pathParameters['departmentId']!;
        final examType = state.uri.queryParameters['type'] ?? 'model';
        return ExamMenuScreen(departmentId: departmentId, examType: examType);
      },
    ),
    GoRoute(
      path: '/materials/:courseId',
      builder: (_, state) {
        final courseId = state.pathParameters['courseId']!;
        final courseName = state.uri.queryParameters['courseName'];
        return MaterialsScreen(courseId: courseId, courseName: courseName);
      },
    ),
    GoRoute(
      path: '/exam/:courseId',
      builder: (_, state) {
        final courseId = state.pathParameters['courseId']!;
        final courseName = state.uri.queryParameters['courseName'];
        final type = state.uri.queryParameters['type'] ?? 'course';
        return ExamScreen(
          courseId: courseId,
          courseName: courseName,
          questionType: type,
        );
      },
    ),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
    GoRoute(
      path: '/notifications',
      builder: (_, _) => const NotificationsScreen(),
    ),
    GoRoute(path: '/payment', builder: (_, _) => const PaymentScreen()),
    GoRoute(path: '/support', builder: (_, _) => const SupportScreen()),
  ],
);
