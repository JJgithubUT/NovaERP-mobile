import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';

/// HU18 - Recuperacion y restablecimiento de contrasena.
///
/// PENDIENTE (HU18). Se abre desde "Olvido su contrasena" en LoginScreen (ruta
/// `AppRoutes.recuperarPassword`, ya registrada). Usa `AuthService.
/// recuperarPassword` y `AuthService.restablecerPassword`. Esta pantalla es
/// publica: no hay sesion, asi que no depende de AuthProvider.
///
/// Las pantallas adicionales de la HU (p. ej. captura del token y la nueva
/// contrasena) se crean en esta misma carpeta y se abren con Navigator.push
/// desde aqui, sin tocar AppRoutes.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Recuperar contrasena')),
      body: const Center(child: Text('HU18 pendiente.')),
    );
  }
}
