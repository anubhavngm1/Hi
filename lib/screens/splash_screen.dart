// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 2), _navigate);
  }

  void _navigate() {
    final auth = context.read<AuthProvider>();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.gold,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.travel_explore, size: 56, color: Color(0xFF0B1320)),
              ),
              const SizedBox(height: 24),
              Text(
                'EBO Stay',
                style: const TextStyle(
                  color: AppTheme.gold, fontSize: 38,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tours • Hotels • Activities',
                style: TextStyle(color: AppTheme.gold.withOpacity(0.7), fontSize: 14),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: AppTheme.gold, strokeWidth: 2),
            ],
          ),
        ),
      ),
    );
  }
}
