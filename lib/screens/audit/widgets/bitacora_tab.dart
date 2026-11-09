import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';

/// HU21 - Consulta de bitacora de auditoria del tenant.
///
/// Guia: usar `ListaPaginada<EventoAuditoria>` (core/widgets) con
/// `AuditoriaService.bitacora`, con filtros por usuario, fecha, tipo de
/// operacion y entidad afectada; vista estrictamente de solo lectura. Al tocar
/// un evento abrir `abrirDetalleEvento` (screens/audit/detalle_evento.dart).
///
/// Exportable a CSV o PDF con `AuditoriaService.exportarBitacora` y
/// `guardarArchivo` (core/utils/descarga.dart), solo con
/// `Permisos.bitacoraExportar`.
///
/// Error de consulta: "No fue posible consultar la bitacora de auditoria."
///
/// Contrato que usa AuditoriaScreen: la clase `BitacoraTab`. Conservar el
/// nombre.
class BitacoraTab extends StatefulWidget {
  const BitacoraTab({super.key});

  @override
  State<BitacoraTab> createState() => BitacoraTabState();
}

class BitacoraTabState extends State<BitacoraTab> {
  /// Vuelve a pedir la primera pagina con los filtros vigentes.
  void recargar() {
    // TODO(HU21): recargar la lista paginada.
  }

  @override
  Widget build(BuildContext context) {
    // TODO(HU21): reemplazar este marcador por la bitacora.
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'HU21: consulta de bitácora pendiente.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.grey),
        ),
      ),
    );
  }
}
