import '../core/network/api_client.dart';
import '../core/network/archivo_descargado.dart';
import '../models/paginado.dart';
import '../models/reportes.dart';

/// Reportes del dominio core (EP05: RF-23).
///
/// REPARTO DEL SPRINT: cada HU implementa SOLO su bloque (los marcados con
/// "HUxx"). Los bloques estan separados a proposito para que los pull requests
/// no se pisen. No muevas ni reordenes metodos ajenos.
class ReportesService {
  // ignore: unused_field -- lo usan los bloques de HU23
  final ApiClient _api = ApiClient.instancia;

  // ===================================================================
  // HU23 - Reporte de actividad de usuarios
  // ===================================================================

  /// Actividad consolidada por usuario del tenant, ordenada por nombre.
  ///
  /// GET [ApiConstants.reporteActividad]
  ///   query: page, desde, hasta (AAAA-MM-DD), departamento, puesto
  /// Exige `core:reportes:leer`. El backend limita el reporte al tenant del
  /// solicitante. El rango de fechas acota las sesiones y acciones contadas.
  Future<Paginado<ActividadUsuario>> actividad({
    int pagina = 1,
    DateTime? desde,
    DateTime? hasta,
    String? departamento,
    String? puesto,
  }) async {
    // TODO(HU23): implementar.
    throw UnimplementedError('HU23: ReportesService.actividad');
  }

  /// Exporta el reporte COMPLETO (no solo la pagina visible) a CSV o PDF.
  ///
  /// GET [ApiConstants.reporteActividad]   query: formato=csv|pdf, filtros...
  /// El backend rechaza la exportacion si supera su tope de filas (422). Usar
  /// `ApiClient.descargar` y entregar el archivo con `guardarArchivo`
  /// (core/utils/descarga.dart).
  Future<ArchivoDescargado> exportarActividad({
    required String formato,
    DateTime? desde,
    DateTime? hasta,
    String? departamento,
    String? puesto,
  }) async {
    // TODO(HU23): implementar.
    throw UnimplementedError('HU23: ReportesService.exportarActividad');
  }

  // ===================================================================
  // BASE (ya hecho)
  // ===================================================================

  /// Descarta parametros nulos o vacios antes de armar el query string.
  // ignore: unused_element -- lo usan los bloques de HU23
  Map<String, dynamic> _consulta(Map<String, dynamic> parametros) {
    final limpio = <String, dynamic>{};
    parametros.forEach((clave, valor) {
      if (valor == null) return;
      if (valor is String && valor.trim().isEmpty) return;
      limpio[clave] = valor;
    });
    return limpio;
  }

  /// El backend valida los rangos como fecha: se manda solo AAAA-MM-DD.
  // ignore: unused_element -- lo usan los bloques de HU23
  String? _soloFecha(DateTime? fecha) {
    if (fecha == null) return null;
    String dd(int n) => n.toString().padLeft(2, '0');
    return '${fecha.year}-${dd(fecha.month)}-${dd(fecha.day)}';
  }
}
