/// Perfil del usuario autenticado, tal como lo devuelve `GET /api/core/me/`.
class Usuario {
  final String id;
  final String nombreCompleto;
  final String correo;

  /// ACTIVO / SUSPENDIDO / PENDIENTE, segun el catalogo del backend.
  final String estado;

  final bool mfaEnrolado;

  /// Ultimo login exitoso, tomado de la bitacora. Nulo en el primer acceso.
  final DateTime? ultimoAcceso;

  const Usuario({
    required this.id,
    required this.nombreCompleto,
    required this.correo,
    required this.estado,
    required this.mfaEnrolado,
    this.ultimoAcceso,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    final acceso = json['ultimo_acceso'] as String?;
    return Usuario(
      id: json['id']?.toString() ?? '',
      nombreCompleto: json['nombre_completo']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      mfaEnrolado: json['mfa_enrolado'] == true,
      ultimoAcceso: acceso == null ? null : DateTime.tryParse(acceso),
    );
  }

  /// Iniciales para el avatar, sin depender de que el nombre tenga apellido.
  String get iniciales {
    final partes = nombreCompleto.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}

/// Empresa (tenant) a la que pertenece la sesion.
class Tenant {
  final String id;
  final String slug;
  final String razonSocial;
  final String estado;
  final String plan;

  const Tenant({
    required this.id,
    required this.slug,
    required this.razonSocial,
    required this.estado,
    required this.plan,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      razonSocial: json['razon_social']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      plan: json['plan']?.toString() ?? '',
    );
  }
}

/// Contexto completo de la sesion: quien es, en que empresa y que puede hacer.
///
/// Es la respuesta de `/api/core/me/` entera. La app la recarga tras el login y
/// cada vez que reanuda una sesion guardada, de modo que un cambio de permisos
/// hecho desde la web se refleja en el siguiente arranque.
class ContextoSesion {
  final Usuario usuario;
  final Tenant tenant;

  /// Nombres de los roles vigentes. Solo para mostrar: no se autoriza con esto.
  final List<String> roles;

  /// El backend marca asi al TENANT_ADMIN (rol de sistema con bypass total).
  final bool esAdmin;

  /// Conjunto efectivo de codigos de permiso, ya resuelto por el backend.
  final Set<String> permisos;

  /// Modulos contratados y activos del tenant (INVENTARIO, VENTAS, ...).
  final Set<String> modulos;

  const ContextoSesion({
    required this.usuario,
    required this.tenant,
    required this.roles,
    required this.esAdmin,
    required this.permisos,
    required this.modulos,
  });

  factory ContextoSesion.fromJson(Map<String, dynamic> json) {
    final permisos = (json['permisos'] as List? ?? const [])
        .whereType<Map>()
        .map((p) => p['codigo']?.toString())
        .whereType<String>()
        .toSet();

    final modulos = (json['modulos'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => m['codigo']?.toString())
        .whereType<String>()
        .toSet();

    return ContextoSesion(
      usuario: Usuario.fromJson(
        Map<String, dynamic>.from(json['usuario'] as Map? ?? const {}),
      ),
      tenant: Tenant.fromJson(
        Map<String, dynamic>.from(json['tenant'] as Map? ?? const {}),
      ),
      roles: (json['roles'] as List? ?? const [])
          .map((r) => r.toString())
          .toList(),
      esAdmin: json['es_admin'] == true,
      permisos: permisos,
      modulos: modulos,
    );
  }

  /// Etiqueta de rol para mostrar en la interfaz.
  String get rolPrincipal {
    if (roles.isEmpty) return esAdmin ? 'Administrador' : 'Sin rol';
    return roles.join(', ');
  }

  bool puede(String codigo) => permisos.contains(codigo);

  bool puedeAlguno(List<String> codigos) => codigos.any(permisos.contains);

  bool puedeTodos(List<String> codigos) => codigos.every(permisos.contains);
}
