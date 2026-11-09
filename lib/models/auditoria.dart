/// Modelos de la bitacora de auditoria (EP04: RF-20..RF-24).
library;

/// Un evento de la bitacora de auditoria (`GET /api/core/bitacora/`).
///
/// La tabla es append-only: lo que se ve aqui no se puede alterar ni borrar,
/// ni siquiera desde el backend. Por eso este modelo es de solo lectura y la
/// app no ofrece ninguna accion de edicion o baja sobre un evento.
///
/// Campos obligatorios de cada registro (RF-20): marca de tiempo en UTC, tenant,
/// usuario, IP de origen, tipo de operacion, id de la entidad afectada y el
/// payload diferencial ([valoresAntes] y [valoresDespues]). El backend enmascara
/// los datos sensibles de esos valores como `[REDACTED]`.
class EventoAuditoria {
  final int id;

  /// Momento del evento, en UTC.
  final DateTime? ocurridoEn;

  /// Quien lo origino. Nulo en eventos del sistema.
  final String? usuarioId;

  /// Tabla o recurso afectado: usuario, rol, sesion...
  final String entidad;

  /// Identificador de la fila afectada.
  final String? entidadId;

  /// INSERT, UPDATE, DELETE, LOGIN, LOGIN_FAILED, EXPORT...
  final String operacion;

  final String criticidad;
  final String? ipOrigen;

  /// Estado de la entidad antes y despues del cambio (payload diferencial).
  final Map<String, dynamic>? valoresAntes;
  final Map<String, dynamic>? valoresDespues;

  const EventoAuditoria({
    required this.id,
    required this.entidad,
    required this.operacion,
    required this.criticidad,
    this.ocurridoEn,
    this.usuarioId,
    this.entidadId,
    this.ipOrigen,
    this.valoresAntes,
    this.valoresDespues,
  });

  factory EventoAuditoria.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? valores(Object? crudo) =>
        crudo is Map ? Map<String, dynamic>.from(crudo) : null;

    final momento = json['ocurrido_en']?.toString();
    return EventoAuditoria(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ocurridoEn: momento == null ? null : DateTime.tryParse(momento),
      usuarioId: json['usuario_id']?.toString(),
      entidad: json['entidad']?.toString() ?? '',
      entidadId: json['entidad_id']?.toString(),
      operacion: json['operacion']?.toString() ?? '',
      criticidad: json['criticidad']?.toString() ?? '',
      ipOrigen: json['ip_origen']?.toString(),
      valoresAntes: valores(json['valores_antes']),
      valoresDespues: valores(json['valores_despues']),
    );
  }

  /// Inserciones, modificaciones y bajas: las que cuentan como "acciones".
  bool get esCambio =>
      const {'INSERT', 'UPDATE', 'DELETE'}.contains(operacion.toUpperCase());

  /// Campos del payload cuyo valor el backend enmascaro.
  List<String> get camposEnmascarados {
    final campos = <String>{};
    for (final valores in [valoresAntes, valoresDespues]) {
      valores?.forEach((clave, valor) {
        if (valor == '[REDACTED]') campos.add(clave);
      });
    }
    return campos.toList()..sort();
  }
}
