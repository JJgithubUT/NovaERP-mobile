import 'package:flutter/foundation.dart' show visibleForTesting;

import '../core/config/api_constants.dart';
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
  final ApiClient _api = ApiClient.instancia;

  // ===================================================================
  // HU23 - Reporte de actividad de usuarios
  // ===================================================================

  /// Actividad consolidada por usuario del tenant, ordenada por nombre.
  ///
  /// GET [ApiConstants.reporteActividad]
  ///   query: page, page_size, desde, hasta (AAAA-MM-DD), departamento, puesto
  /// Exige `core:reportes:leer`. El backend limita el reporte al tenant del
  /// solicitante. El rango de fechas acota las sesiones y las acciones contadas,
  /// no la lista de usuarios ni el ultimo acceso. [hasta] es INCLUSIVO aqui:
  /// ver [_diaSiguiente].
  Future<Paginado<ActividadUsuario>> actividad({
    int pagina = 1,
    int? tamanoPagina,
    DateTime? desde,
    DateTime? hasta,
    String? departamento,
    String? puesto,
  }) async {
    final json = await _api.get(
      ApiConstants.reporteActividad,
      query: _consulta({
        'page': pagina,
        'page_size': tamanoPagina,
        'desde': _soloFecha(desde),
        'hasta': _soloFecha(_diaSiguiente(hasta)),
        'departamento': departamento,
        'puesto': puesto,
      }),
    );
    return Paginado.fromJson(json, ActividadUsuario.fromJson);
  }

  /// Exporta el reporte COMPLETO (no solo la pagina visible) a CSV o PDF.
  ///
  /// GET [ApiConstants.reporteActividad]   query: formato=csv|pdf, filtros...
  /// Mismo permiso que la consulta (`core:reportes:leer`). El archivo trae los
  /// metadatos (tenant, quien lo genero, fecha y filtros aplicados). El backend
  /// rechaza la exportacion si supera 20 000 filas (400).
  Future<ArchivoDescargado> exportarActividad({
    required String formato,
    DateTime? desde,
    DateTime? hasta,
    String? departamento,
    String? puesto,
  }) {
    return _api.descargar(
      ApiConstants.reporteActividad,
      query: _consulta({
        'formato': formato,
        'desde': _soloFecha(desde),
        'hasta': _soloFecha(_diaSiguiente(hasta)),
        'departamento': departamento,
        'puesto': puesto,
      }),
      nombreBase: nombreBase(DateTime.now().toUtc()),
    );
  }

  /// Nombre del archivo exportado, con el mismo patron que arma el backend
  /// (`actividad_<tenant>_<AAAAMMDD>_<HHMMSS>`). En web el cliente no puede leer
  /// `Content-Disposition`, asi que el nombre se arma aqui.
  @visibleForTesting
  static String nombreBase(
    DateTime ahoraUtc, {
    String tenant = ApiConstants.tenantSlug,
  }) {
    String dd(int n) => n.toString().padLeft(2, '0');
    final fecha = '${ahoraUtc.year}${dd(ahoraUtc.month)}${dd(ahoraUtc.day)}';
    final hora =
        '${dd(ahoraUtc.hour)}${dd(ahoraUtc.minute)}${dd(ahoraUtc.second)}';
    return 'actividad_${tenant}_${fecha}_$hora';
  }

  /// Departamentos y puestos que existen en el tenant, para los filtros.
  ///
  /// El backend no tiene un catalogo y filtra por IGUALDAD EXACTA (distingue
  /// mayusculas y tildes), asi que un campo de texto libre daria falsos vacios.
  /// Se arman con los valores del propio reporte, que no exige otro permiso que
  /// el del reporte. Se conserva el valor ORIGINAL (sin recortar) porque es el
  /// que se manda de vuelta. Tope: [maxPaginas] paginas de 100 usuarios.
  Future<({List<String> departamentos, List<String> puestos})>
  catalogoAdscripcion({int maxPaginas = 10}) async {
    final departamentos = <String>{};
    final puestos = <String>{};
    var pagina = 1;
    while (pagina <= maxPaginas) {
      final lote = await actividad(pagina: pagina, tamanoPagina: 100);
      for (final fila in lote.elementos) {
        final d = fila.departamento;
        final p = fila.puesto;
        if (d != null && d.trim().isNotEmpty) departamentos.add(d);
        if (p != null && p.trim().isNotEmpty) puestos.add(p);
      }
      if (!lote.hayMasPaginas) break;
      pagina++;
    }
    return (
      departamentos: departamentos.toList()..sort(),
      puestos: puestos.toList()..sort(),
    );
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

  /// El backend trata `hasta` como EXCLUSIVO (compara contra las 00:00 de ese
  /// dia en la zona horaria del servidor, `TIME_ZONE`), asi que elegir "hasta el
  /// 16" dejaria fuera todo el dia 16. Para incluir el dia elegido se manda el
  /// siguiente. La app manda el dia del calendario del dispositivo y el backend
  /// lo interpreta en su zona. Si algun dia el backend pasa a inclusivo, hay que
  /// quitar esta compensacion (y la de AuditoriaService).
  @visibleForTesting
  static DateTime? diaSiguiente(DateTime? fecha) {
    if (fecha == null) return null;
    return DateTime(fecha.year, fecha.month, fecha.day + 1);
  }

  DateTime? _diaSiguiente(DateTime? fecha) => diaSiguiente(fecha);
}
