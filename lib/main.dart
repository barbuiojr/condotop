// import 'package:device_preview/device_preview.dart';
import 'package:condotop/utils/api.dart';
import 'package:condotop/utils/session_service.dart';
import 'package:condotop/views/dashboar.dart';
import 'package:condotop/views/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  // Configurar navigator key global para o interceptor
  ApiService.navigatorKey = GlobalKey<NavigatorState>();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      navigatorKey: ApiService.navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthCheck(),
        '/login': (context) => const Login(),
        '/dashboard': (context) => const Dashboard(),
      },
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    // Aguardar o primeiro frame ser renderizado antes de navegar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final sessionService = SessionService();
    final isAuthenticated = sessionService.isAuthenticated();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => isAuthenticated ? const Dashboard() : const Login(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
