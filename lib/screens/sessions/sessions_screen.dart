import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';

/// HU19 - Consulta y revocacion de sesiones activas.
///
/// PENDIENTE (HU19). Se abre desde Perfil > Seguridad > "Sesiones activas"
/// (ruta `AppRoutes.sesiones`, ya registrada). Datos via `SesionesService` y
/// el modelo `Sesion`. Si el usuario revoca la sesion en curso o el backend
/// responde 401, ApiClient ya limpia la sesion y AuthGate devuelve al login.
class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sesiones activas')),
      body: const Center(child: Text('HU19 pendiente.')),
    );
  }
}
