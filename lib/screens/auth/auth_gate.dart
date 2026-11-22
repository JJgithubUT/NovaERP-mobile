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
  late final AuthProvider _auth;
  late EstadoSesion _estadoAnterior;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>();
    _estadoAnterior = _auth.estado;
    _auth.addListener(_alCambiarSesion);
    // Tras el primer frame, para no notificar oyentes durante el build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _auth.inicializar();
    });
  }

  @override
  void dispose() {
    _auth.removeListener(_alCambiarSesion);
    super.dispose();
  }

  /// Si la sesion se pierde estando dentro (401 por sesion vencida o revocada,
  /// o cierre de sesion), cierra las pantallas apiladas encima: AuthGate ya
  /// muestra el login debajo, pero una pantalla abierta con push (detalle de
  /// usuario, sesiones, formularios...) seguiria tapandolo.
  void _alCambiarSesion() {
    final estado = _auth.estado;
    final perdioLaSesion =
        _estadoAnterior == EstadoSesion.activa && estado != EstadoSesion.activa;
    _estadoAnterior = estado;
    if (perdioLaSesion && mounted) {
      Navigator.of(context).popUntil((ruta) => ruta.isFirst);
    }
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
