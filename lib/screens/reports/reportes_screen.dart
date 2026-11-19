import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/permisos.dart';
import '../../core/config/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'widgets/actividad_tab.dart';
import 'widgets/alertas_tab.dart';

/// Modulo de reportes y notificaciones (EP05): actividad de usuarios y alertas
/// de seguridad.
///
/// Las pestanas salen de los permisos efectivos, no del nombre del rol:
///   Actividad -> `core:reportes:leer`
///   Alertas   -> `core:bitacora:leer`
/// La bitacora de auditoria vive en su propio modulo (screens/audit).
///
/// Este archivo es BASE: ninguna HU de EP05 necesita editarlo. Cada una vive en
/// su archivo:
///   HU23 -> widgets/actividad_tab.dart (reporte, filtros y exportacion)
///   HU24 -> screens/audit/widgets/accion_exportar_bitacora.dart
///   HU25 -> widgets/alertas_tab.dart (alertas de seguridad)
class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final pestanas = <_Pestana>[
      if (auth.puede(Permisos.reportesLeer))
        const _Pestana('Actividad', Icons.insights_outlined, ActividadTab()),
      if (auth.puede(Permisos.bitacoraLeer))
        const _Pestana('Alertas', Icons.shield_outlined, AlertasTab()),
    ];

    if (pestanas.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _barra(null),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Su rol no tiene acceso a los reportes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey),
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: pestanas.length,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _barra(pestanas),
        body: TabBarView(children: [for (final p in pestanas) p.contenido]),
      ),
    );
  }

  PreferredSizeWidget _barra(List<_Pestana>? pestanas) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.black,
      title: const Text(
        'Reportes',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      bottom: pestanas == null || pestanas.length < 2
          ? null
          : TabBar(
              indicatorColor: AppColors.primaryLight,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.grey,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                for (final p in pestanas)
                  Tab(icon: Icon(p.icono, size: 20), text: p.etiqueta),
              ],
            ),
    );
  }
}

class _Pestana {
  const _Pestana(this.etiqueta, this.icono, this.contenido);

  final String etiqueta;
  final IconData icono;
  final Widget contenido;
}
