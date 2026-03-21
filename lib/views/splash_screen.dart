import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goToNextScreen();
  }

  Future<void> _goToNextScreen() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed('/auth-check');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image(
          image: AssetImage('assets/logo/logo_condotop_without_bckground.png'),
          height: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
