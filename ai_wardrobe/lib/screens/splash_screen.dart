import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/theme.dart';
import '../providers/auth_provider.dart';
import 'onboarding_screen.dart';
import 'navigation_shell.dart';
import 'login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _checkNavigationState();
  }

  Future<void> _checkNavigationState() async {
    // Wait for the full animation duration
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isLoading) {
      Future.delayed(const Duration(milliseconds: 500), _checkNavigationState);
      return;
    }

    if (!authState.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
      return;
    }

    final profileState = ref.read(profileProvider);
    profileState.profile.when(
      data: (user) {
        if (user == null || user.name.isEmpty) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const OnboardingScreen(),
              transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const NavigationShell(),
              transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      },
      error: (_, __) {
        // Fallback to onboarding if connection fails/missing database config
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const OnboardingScreen(),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      },
      loading: () {
        // Retry checking profile after a small delay if it is still loading
        Future.delayed(const Duration(milliseconds: 1000), _checkNavigationState);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtelierTheme.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'AI WARDROBE',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w200,
                  color: AtelierTheme.primaryText,
                  letterSpacing: 8.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'YOUR INTELLIGENT COUTURE ASSISTANT',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AtelierTheme.secondaryText,
                  letterSpacing: 4.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
