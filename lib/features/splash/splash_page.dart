import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() {
    // Wait for 2 seconds before navigating
    Future.delayed(const Duration(seconds: 2), () {
      // Ensure the widget is still mounted before navigating
      if (mounted) {
        // Use go() to replace the splash screen in the navigation stack
        GoRouter.of(context).go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        // Before running, ensure you have added 'assets/logo.png'
        // to your pubspec.yaml file and the file exists.
        child: Image(
          image: AssetImage('assets/crypto_logo.png'),
          width: 150, // Adjust size as needed
        ),
      ),
    );
  }
}
