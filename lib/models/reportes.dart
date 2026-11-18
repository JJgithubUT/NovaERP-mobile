/// Modelos de los reportes del dominio core (EP05: RF-23).
library;

/// Fila del reporte de actividad de usuarios (`GET /api/core/reportes/actividad/`).
///
/// Por usuario del tenant: ultimo acceso, numero de sesiones, numero de acciones
/// CUD auditadas (altas, cambios y bajas) y estado actual. Las sesiones y las
/// acciones se cuentan dentro del rango de fechas pedido; el ultimo acceso no
/// depende del rango.
class ActividadUsuario {
  final String usuarioId;
  final String nombreCompleto;
  final String correo;
  final String? departamento;
  final String? puesto;

  /// activo / pendiente / pendiente_verificacion / suspendido, segun el
  /// catalogo del backend.
  final String estado;

  /// Ultimo ingreso exitoso (evento LOGIN). Nulo si nunca ha entrado.
  final DateTime? ultimoAcceso;
  final int numSesiones;
  final int numAccionesCud;

  const ActividadUsuario({
    required this.usuarioId,
    required this.nombreCompleto,
    required this.correo,
    required this.estado,
    required this.numSesiones,
    required this.numAccionesCud,
    this.departamento,
    this.puesto,
    this.ultimoAcceso,
  });

  factory ActividadUsuario.fromJson(Map<String, dynamic> json) {
    final acceso = json['ultimo_acceso']?.toString();
    return ActividadUsuario(
      usuarioId: json['usuario_id']?.toString() ?? '',
      nombreCompleto: json['nombre_completo']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      departamento: json['departamento']?.toString(),
      puesto: json['puesto']?.toString(),
      estado: json['estado']?.toString() ?? '',
      ultimoAcceso: acceso == null ? null : DateTime.tryParse(acceso),
      numSesiones: (json['num_sesiones'] as num?)?.toInt() ?? 0,
      numAccionesCud: (json['num_acciones_cud'] as num?)?.toInt() ?? 0,
    );
  }

  /// Nunca ha entrado al sistema.
  bool get sinAcceso => ultimoAcceso == null;

  /// Sin sesiones ni acciones en el periodo consultado: candidato a cuenta
  /// inactiva (el objetivo del reporte es planear licencias y detectarlas).
  bool get sinActividad => numSesiones == 0 && numAccionesCud == 0;
}
