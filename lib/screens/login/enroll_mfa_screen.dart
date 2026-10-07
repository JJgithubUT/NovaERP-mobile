import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_colors.dart';
import '../../providers/auth_provider.dart';

/// HU16 - Enrolamiento de MFA (primer acceso o tras un reset del admin).
///
/// PENDIENTE (HU16). AuthGate muestra esta pantalla cuando el estado es
/// [EstadoSesion.enrolandoMfa]. Datos disponibles en
/// `AuthProvider.reto`: `secreto` (se entrega UNA sola vez) y `otpauthUri`
/// (para el QR; el paquete qr_flutter ya esta en pubspec). Al terminar llamar a
/// `AuthProvider.confirmarEnrolamiento()`.
class EnrollMfaScreen extends StatelessWidget {
  const EnrollMfaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Configurar verificacion')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('HU16 pendiente: QR y secreto TOTP.'),
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
