import 'package:flutter/material.dart';
import '../../../screens/splash/splash_screen.dart';
import '../../../screens/login/login_screen.dart';
import '../../../screens/home/home_screen.dart';
import '../../../screens/profile/profile_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      home: (context) => const HomeScreen(),
      profile: (context) => const ProfileScreen(),
    };
  }
}
