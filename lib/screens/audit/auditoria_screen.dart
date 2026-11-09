import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/permisos.dart';
import '../../core/config/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'widgets/bitacora_tab.dart';

/// Modulo de auditoria (EP04): consulta de la bitacora del tenant.
///
/// Solo lectura: la bitacora es append-only y la app no ofrece ninguna accion
/// de edicion o baja sobre un evento. La pantalla sale de los permisos
/// efectivos (`core:bitacora:leer`), no del nombre del rol.
///
/// Este archivo es BASE: ninguna HU de EP04 necesita editarlo. Cada una vive en
/// su archivo:
///   HU20 -> detalle_evento.dart   (detalle de un evento y sus campos obligatorios)
///   HU21 -> widgets/bitacora_tab.dart (listado con filtros y exportacion)
class AuditoriaScreen extends StatelessWidget {
  const AuditoriaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final puedeVer = auth.puede(Permisos.bitacoraLeer);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.black,
        title: const Text(
          'Auditoría',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: puedeVer
          ? const BitacoraTab()
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Su rol no tiene acceso a la bitácora de auditoría.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey),
                ),
              ),
            ),
    );
  }
}
