import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import '../login/enroll_mfa_screen.dart';
import '../login/login_screen.dart';
import '../login/otp_screen.dart';
import '../splash/splash_screen.dart';

/// Decide que pantalla toca segun la fase de la sesion.
///
/// El login del backend tiene pasos intermedios (reto OTP, enrolamiento) y una
/// sesion puede caerse en cualquier momento porque el servidor la revoque. Con
/// navegacion imperativa eso obliga a acordarse de un pushReplacement en cada
/// sitio; aqui el estado manda y la pantalla es una consecuencia.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Tras el primer frame, para no notificar oyentes durante el build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().inicializar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.select<AuthProvider, EstadoSesion>((a) => a.estado);

    return switch (estado) {
      EstadoSesion.comprobando => const SplashScreen(),
      EstadoSesion.sinSesion => const LoginScreen(),
      EstadoSesion.enrolandoMfa => const EnrollMfaScreen(),
      EstadoSesion.esperandoOtp => const OtpScreen(),
      EstadoSesion.activa => const HomeScreen(),
    };
  }
}
