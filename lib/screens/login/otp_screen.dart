import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_colors.dart';
import '../../providers/auth_provider.dart';

/// HU16 - Fase 2 del login: codigo TOTP de la app autenticadora.
///
/// PENDIENTE (HU16). AuthGate muestra esta pantalla cuando el estado es
/// [EstadoSesion.esperandoOtp]. Al validar el codigo con
/// `AuthProvider.validarOtp` el estado pasa a `activa` y AuthGate navega solo;
/// esta pantalla no debe hacer Navigator.push al terminar.
class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Verificacion en dos pasos')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('HU16 pendiente: captura del codigo OTP.'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.read<AuthProvider>().cancelarReto(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
