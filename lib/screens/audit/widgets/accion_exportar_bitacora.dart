import 'package:flutter/material.dart';

/// HU24 - Exportacion de la bitacora de auditoria. Boton de la cabecera de la
/// bitacora (screens/audit/widgets/bitacora_tab.dart), junto a los filtros.
///
/// Guia: un menu con "Exportar a CSV" y "Exportar a PDF" que llama a
/// `AuditoriaService.exportarBitacora` con los MISMOS filtros que la lista
/// (los recibe como parametros) y entrega el archivo con `guardarArchivo`
/// (core/utils/descarga.dart). Mostrar solo con
/// `AuthProvider.puede(Permisos.bitacoraExportar)`.
///
/// El backend agrega al archivo los metadatos (quien lo genero, fecha y hora,
/// filtros aplicados) y registra cada exportacion como un evento EXPORT en la
/// propia bitacora. Error: "No fue posible exportar la bitacora de auditoria."
///
/// Contrato que usa BitacoraTab: conservar el nombre de la clase y sus
/// parametros.
class AccionExportarBitacora extends StatelessWidget {
  const AccionExportarBitacora({
    super.key,
    this.usuarioId,
    this.operacion,
    this.entidad,
    this.desde,
    this.hasta,
  });

  /// Filtros vigentes de la bitacora.
  final String? usuarioId;
  final String? operacion;
  final String? entidad;
  final DateTime? desde;
  final DateTime? hasta;

  @override
  Widget build(BuildContext context) {
    // TODO(HU24): implementar la exportacion.
    return const IconButton(
      tooltip: 'HU24 pendiente',
      onPressed: null,
      icon: Icon(Icons.file_download_outlined),
    );
  }
}
