import 'package:flutter/material.dart';

import '../../screens/auth/auth_gate.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/recovery/forgot_password_screen.dart';
import '../../screens/sessions/sessions_screen.dart';

/// Rutas con nombre de la app.
///
/// El flujo de acceso (splash / login / OTP / enrolamiento / home) NO vive
/// aqui: lo resuelve AuthGate a partir del estado de la sesion, para que una
/// sesion revocada devuelva al login desde cualquier punto sin que cada
/// pantalla tenga que preverlo. Estas rutas son las que se apilan encima.
///
/// Todas las rutas del sprint ya estan registradas: ninguna HU necesita editar
/// este archivo (evita conflictos de merge).
class AppRoutes {
  static const String raiz = '/';
  static const String profile = '/profile';
  static const String recuperarPassword = '/recuperar-password';
  static const String sesiones = '/sesiones';

  static Map<String, WidgetBuilder> get routes {
    return {
      raiz: (context) => const AuthGate(),
      profile: (context) => const ProfileScreen(),
      recuperarPassword: (context) => const ForgotPasswordScreen(),
      sesiones: (context) => const SessionsScreen(),
    };
  }
}
