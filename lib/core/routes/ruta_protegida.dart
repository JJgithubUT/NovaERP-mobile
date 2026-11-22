import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../screens/splash/splash_screen.dart';

/// Envuelve las rutas con nombre que exigen sesion (perfil, sesiones...).
///
/// En web una ruta con nombre se puede abrir tecleando la URL (`/#/sesiones`)
/// sin pasar por AuthGate. Sin este guardia la pantalla se abria sin sesion:
/// vacia, porque el backend responde 401, pero visible. Aqui:
///   - mientras se comprueba la sesion guardada se muestra el splash, para que
///     la pantalla no dispare peticiones antes de tener el token;
///   - con la sesion activa se muestra la pantalla;
///   - sin sesion (nunca la hubo, expiro o fue revocada) la ruta se retira y
///     queda a la vista AuthGate, que muestra el login.
class RutaProtegida extends StatelessWidget {
  const RutaProtegida({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final estado = context.select<AuthProvider, EstadoSesion>((a) => a.estado);

    switch (estado) {
      case EstadoSesion.activa:
        return child;
      case EstadoSesion.comprobando:
        return const SplashScreen();
      case EstadoSesion.sinSesion:
      case EstadoSesion.esperandoOtp:
      case EstadoSesion.enrolandoMfa:
        // No se navega durante el build: se retira la ruta al terminar el frame.
        WidgetsBinding.instance.addPostFrameCallback((_) => _salir(context));
        return const SplashScreen();
    }
  }

  void _salir(BuildContext context) {
    if (!context.mounted) return;
    final ruta = ModalRoute.of(context);
    // Ya retirada (por ejemplo, AuthGate cerro todas las pantallas apiladas).
    if (ruta == null || !ruta.isActive) return;

    final navegador = Navigator.of(context);
    if (ruta.isFirst) {
      // No hay AuthGate debajo: se pone en su lugar. Se usa '/' (AppRoutes.raiz)
      // literal para no importar app_routes.dart, que importa este archivo.
      navegador.pushReplacementNamed('/');
    } else {
      navegador.removeRoute(ruta);
    }
  }
}
