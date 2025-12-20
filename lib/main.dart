import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_finance_assistant/core/di/injection_container.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter_finance_assistant/presentation/screens/auth/forgot_password_screen.dart';
import 'package:flutter_finance_assistant/presentation/screens/auth/login_screen.dart';
import 'package:flutter_finance_assistant/presentation/screens/auth/register_screen.dart';
import 'package:flutter_finance_assistant/presentation/screens/main/main_screen.dart';
import 'package:flutter_finance_assistant/presentation/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize dependencies
  await initDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuthBloc>(),
      child: MaterialApp(
        title: 'Flutter Finance Assistant',
        debugShowCheckedModeBanner: false,

        // Themes
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,

        // Routes
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/main': (context) => const MainScreen(),
        },
      ),
    );
  }
}
