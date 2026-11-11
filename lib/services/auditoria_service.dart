import '../core/config/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/network/archivo_descargado.dart';
import '../models/auditoria.dart';
import '../models/paginado.dart';
import 'personal_service.dart';

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
    final json = await _api.get(
      ApiConstants.bitacora,
      query: _consulta({
        'page': pagina,
        'usuario_id': usuarioId,
        'operacion': operacion,
        'entidad': entidad,
        'desde': _soloFecha(desde),
        'hasta': _soloFecha(hasta),
      }),
    );
    return Paginado.fromJson(json, EventoAuditoria.fromJson);
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
    return _api.descargar(
      ApiConstants.bitacoraExportar,
      query: _consulta({
        'formato': formato,
        'usuario_id': usuarioId,
        'operacion': operacion,
        'entidad': entidad,
        'desde': _soloFecha(desde),
        'hasta': _soloFecha(hasta),
      }),
      nombreBase: 'bitacora_auditoria',
    );
  }

  /// Indice `usuario_id -> nombre` para mostrar nombres en lugar de ids.
  ///
  /// La bitacora solo trae `usuario_id`. Si quien consulta no puede leer el
  /// directorio de usuarios, devolver un mapa vacio (la pantalla muestra el id
  /// abreviado): no debe romper la consulta.
  Future<Map<String, String>> nombresDeUsuario() async {
    final indice = <String, String>{};
    final personal = PersonalService();
    try {
      var pagina = 1;
      while (pagina <= 20) {
        final lote = await personal.usuarios(pagina: pagina);
        for (final u in lote.elementos) {
          indice[u.id] = u.nombreCompleto;
        }
        if (!lote.hayMasPaginas) break;
        pagina++;
      }
    } on ApiException {
      // Sin permiso para leer el directorio la bitacora sigue siendo legible:
      // se muestra el id abreviado en lugar del nombre.
    }
    return indice;
  }

  // ===================================================================
  // BASE (ya hecho)
  // ===================================================================

  /// Descarta parametros nulos o vacios antes de armar el query string.
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
  String? _soloFecha(DateTime? fecha) {
    if (fecha == null) return null;
    String dd(int n) => n.toString().padLeft(2, '0');
    return '${fecha.year}-${dd(fecha.month)}-${dd(fecha.day)}';
  }
}
