import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image – path matches pubspec.yaml
          Image.asset(
            'assets/images/bg.jpg',
            fit: BoxFit.cover,
          ),

          // Dark overlay for text contrast
          Container(
            color: Colors.black.withOpacity(0.55),
          ),

          // Content – aligned to the bottom centre
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo – now uses app icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App name
                    Text(
                      'Exora',
                      style: AppTextStyles.heading1.copyWith(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tagline
                    Text(
                      'Your ultimate exit exam preparation companion. Past papers, model exams, and detailed explanations.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withOpacity(0.95),
                        height: 1.5,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Get Started button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => context.push('/register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGradientStart,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          shadowColor: AppColors.primaryGradientStart.withOpacity(0.4),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Login link
                    TextButton(
                      onPressed: () => context.push('/login'),
                      child: Text(
                        'Already have an account? Login',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}