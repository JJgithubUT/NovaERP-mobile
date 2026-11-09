import '../core/network/api_client.dart';
import '../core/network/archivo_descargado.dart';
import '../models/auditoria.dart';
import '../models/paginado.dart';

/// Bitacora de auditoria del tenant (EP04: RF-20..RF-24).
///
/// REPARTO DEL SPRINT: cada HU implementa SOLO su bloque (los marcados con
/// "HUxx"). Los bloques estan separados a proposito para que los pull requests
/// no se pisen. No muevas ni reordenes metodos ajenos.
///
/// HU20 (registro automatico) es un comportamiento del backend: no tiene
/// metodo aqui. Su parte en la app es la pantalla de detalle de un evento
/// (screens/audit/detalle_evento.dart).
class AuditoriaService {
  // ignore: unused_field -- lo usan los bloques de HU21
  final ApiClient _api = ApiClient.instancia;

  // ===================================================================
  // HU21 - Consulta de bitacora de auditoria del tenant
  // ===================================================================

  /// Bitacora del tenant, de lo mas reciente a lo mas antiguo. Solo lectura.
  ///
  /// GET [ApiConstants.bitacora]
  ///   query: page, usuario_id, operacion, entidad, desde, hasta (AAAA-MM-DD)
  /// El backend aplica solo el filtro de tenant. Exige `core:bitacora:leer`.
  Future<Paginado<EventoAuditoria>> bitacora({
    int pagina = 1,
    String? usuarioId,
    String? operacion,
    String? entidad,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    // TODO(HU21): implementar.
    throw UnimplementedError('HU21: AuditoriaService.bitacora');
  }

  /// Exporta la bitacora con los mismos filtros de [bitacora].
  ///
  /// GET [ApiConstants.bitacoraExportar]   query: formato=csv|pdf, filtros...
  /// Exige `core:bitacora:exportar`. El backend registra la exportacion como un
  /// evento EXPORT. Usar `ApiClient.descargar` y entregar el archivo con
  /// `guardarArchivo` (core/utils/descarga.dart).
  Future<ArchivoDescargado> exportarBitacora({
    required String formato,
    String? usuarioId,
    String? operacion,
    String? entidad,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    // TODO(HU21): implementar.
    throw UnimplementedError('HU21: AuditoriaService.exportarBitacora');
  }

  /// Indice `usuario_id -> nombre` para mostrar nombres en lugar de ids.
  ///
  /// La bitacora solo trae `usuario_id`. Si quien consulta no puede leer el
  /// directorio de usuarios, devolver un mapa vacio (la pantalla muestra el id
  /// abreviado): no debe romper la consulta.
  Future<Map<String, String>> nombresDeUsuario() async {
    // TODO(HU21): implementar.
    throw UnimplementedError('HU21: AuditoriaService.nombresDeUsuario');
  }

  // ===================================================================
  // BASE (ya hecho)
  // ===================================================================

  /// Descarta parametros nulos o vacios antes de armar el query string.
  // ignore: unused_element -- lo usan los bloques de HU21
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
  // ignore: unused_element -- lo usan los bloques de HU21
  String? _soloFecha(DateTime? fecha) {
    if (fecha == null) return null;
    String dd(int n) => n.toString().padLeft(2, '0');
    return '${fecha.year}-${dd(fecha.month)}-${dd(fecha.day)}';
  }
}
