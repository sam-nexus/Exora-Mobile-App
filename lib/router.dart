import 'package:exora/screens/reset_password_screen.dart';
import 'package:exora/screens/verify_reset_code_screen.dart';
import 'package:go_router/go_router.dart'; // ← add
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/exam_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/splash_screen.dart'; // ← add
import 'screens/forgot_password_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash', // ← changed from '/welcome'
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()), // ← new
    GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
    GoRoute(
      path: '/courses/:departmentId',
      builder: (_, state) =>
          CoursesScreen(departmentId: state.pathParameters['departmentId']!),
    ),
    GoRoute(
      path: '/exam/:courseId',
      builder: (_, state) {
        final courseId = state.pathParameters['courseId']!;
        final courseName = state.uri.queryParameters['courseName'];
        return ExamScreen(courseId: courseId, courseName: courseName);
      },
    ),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
    GoRoute(
      path: '/notifications',
      builder: (_, _) => const NotificationsScreen(),
    ),
    GoRoute(path: '/payment', builder: (_, _) => const PaymentScreen()),
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
  ],
);
