import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';

/// HU23 - Reporte de actividad de usuarios.
///
/// Guia: usar `ListaPaginada<ActividadUsuario>` (core/widgets) con
/// `ReportesService.actividad`. Cada fila muestra ultimo acceso, numero de
/// sesiones, numero de acciones CUD y estado. Filtros: rango de fechas
/// (`FiltroFechas`, widgets/filtro_fechas.dart, ya en la base) y
/// departamento/puesto. Exportable a CSV y PDF con
/// `ReportesService.exportarActividad` y `guardarArchivo`
/// (core/utils/descarga.dart).
///
/// Error de generacion: "No fue posible generar el reporte de actividad."
///
/// Contrato que usa ReportesScreen: la clase `ActividadTab`. Conservar el
/// nombre.
class ActividadTab extends StatefulWidget {
  const ActividadTab({super.key});

  @override
  State<ActividadTab> createState() => ActividadTabState();
}

class ActividadTabState extends State<ActividadTab> {
  /// Vuelve a pedir la primera pagina con los filtros vigentes.
  void recargar() {
    // TODO(HU23): recargar la lista paginada.
  }

  @override
  Widget build(BuildContext context) {
    // TODO(HU23): reemplazar este marcador por el reporte.
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'HU23: reporte de actividad pendiente.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.grey),
        ),
      ),
    );
  }
}
