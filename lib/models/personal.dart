/// Modelos del modulo de personal (usuarios y roles del tenant).
library;

/// Fila del directorio de usuarios (RF-06).
class UsuarioDirectorio {
  final String id;
  final String correo;
  final String nombreCompleto;
  final String? telefono;
  final String? puesto;
  final String? departamento;

  /// activo / suspendido / pendiente, segun el catalogo del backend.
  final String estado;

  final List<String> roles;
  final DateTime? ultimoAcceso;
  final DateTime? creadoEn;

  const UsuarioDirectorio({
    required this.id,
    required this.correo,
    required this.nombreCompleto,
    required this.estado,
    required this.roles,
    this.telefono,
    this.puesto,
    this.departamento,
    this.ultimoAcceso,
    this.creadoEn,
  });

  factory UsuarioDirectorio.fromJson(Map<String, dynamic> json) {
    final acceso = json['ultimo_acceso']?.toString();
    final creado = json['created_at']?.toString();
    return UsuarioDirectorio(
      id: json['id']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      nombreCompleto: json['nombre_completo']?.toString() ?? '',
      telefono: json['telefono']?.toString(),
      puesto: json['puesto']?.toString(),
      departamento: json['departamento']?.toString(),
      estado: json['estado']?.toString() ?? '',
      roles: (json['roles'] as List? ?? const [])
          .map((r) => r.toString())
          .toList(),
      ultimoAcceso: acceso == null ? null : DateTime.tryParse(acceso),
      creadoEn: creado == null ? null : DateTime.tryParse(creado),
    );
  }

  bool get estaActivo => estado.toLowerCase() == 'activo';
  bool get estaSuspendido => estado.toLowerCase() == 'suspendido';

  /// Alta creada pero sin activar: aun no ha fijado contrasena.
  bool get estaPendiente => estado.toLowerCase() == 'pendiente';

  String get iniciales {
    final partes = nombreCompleto.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}

/// Rol del tenant (RF-11). Un rol es un paquete de permisos; el TENANT_ADMIN
/// es el unico de sistema y autoriza por bypass, sin filas en rol_permiso.
class Rol {
  final String id;
  final String nombre;
  final bool esSistema;
  final bool activo;

  /// El backend lo expone para que la interfaz no pinte al TENANT_ADMIN como
  /// un rol sin permisos.
  final bool accesoTotal;

  final int usuariosAsignados;

  /// Codigos de permiso agrupados por dominio. Vacio en los roles de sistema.
  final Map<String, List<PermisoRol>> permisosPorDominio;

  const Rol({
    required this.id,
    required this.nombre,
    required this.esSistema,
    required this.activo,
    required this.accesoTotal,
    required this.usuariosAsignados,
    required this.permisosPorDominio,
  });

  factory Rol.fromJson(Map<String, dynamic> json) {
    // El backend envia los permisos como LISTA de {dominio, permisos: [...]}
    // (rol_service.serialize_rol). Se acepta tambien un mapa {dominio: [...]}
    // por si alguna version lo entrega asi.
    final permisos = <String, List<PermisoRol>>{};
    final crudo = json['permisos'];
    List<PermisoRol> aPermisos(Object? lista) => (lista as List? ?? const [])
        .whereType<Map>()
        .map((p) => PermisoRol.fromJson(Map<String, dynamic>.from(p)))
        .toList();
    if (crudo is List) {
      for (final grupo in crudo.whereType<Map>()) {
        final dominio = grupo['dominio']?.toString() ?? '';
        permisos[dominio] = aPermisos(grupo['permisos']);
      }
    } else if (crudo is Map) {
      crudo.forEach((dominio, lista) {
        permisos[dominio.toString()] = aPermisos(lista);
      });
    }

    return Rol(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      esSistema: json['es_sistema'] == true,
      activo: json['activo'] == true,
      accesoTotal: json['acceso_total'] == true,
      usuariosAsignados: (json['usuarios_asignados'] as num?)?.toInt() ?? 0,
      permisosPorDominio: permisos,
    );
  }

  int get totalPermisos =>
      permisosPorDominio.values.fold(0, (n, lista) => n + lista.length);

  /// Codigos de todos los permisos del rol. Es lo que precarga el selector al
  /// editar y lo que se envia al guardar.
  Set<String> get codigosPermisos => {
    for (final lista in permisosPorDominio.values)
      for (final p in lista) p.codigo,
  };

  /// Permisos que existen en el rol pero no aplican porque su modulo esta
  /// desactivado en el tenant. El backend los conserva en vez de borrarlos.
  int get permisosInertes => permisosPorDominio.values
      .expand((lista) => lista)
      .where((p) => p.inerte)
      .length;
}

class PermisoRol {
  final String codigo;
  final String dominio;
  final String recurso;
  final String accion;
  final bool inerte;

  /// Texto del catalogo maestro (p. ej. "RF-52 Configurar umbral de
  /// aprobacion"). Puede venir vacio.
  final String descripcion;

  const PermisoRol({
    required this.codigo,
    required this.dominio,
    required this.recurso,
    required this.accion,
    required this.inerte,
    this.descripcion = '',
  });

  factory PermisoRol.fromJson(Map<String, dynamic> json) => PermisoRol(
    codigo: json['codigo']?.toString() ?? '',
    dominio: json['dominio']?.toString() ?? '',
    recurso: json['recurso']?.toString() ?? '',
    accion: json['accion']?.toString() ?? '',
    inerte: json['inerte'] == true,
    descripcion: json['descripcion']?.toString() ?? '',
  );
}

/// Un dominio del catalogo maestro de permisos (`GET /api/core/permisos/`).
/// Es el origen del selector de permisos al crear o editar un rol: solo se
/// pueden elegir permisos de este catalogo. Los de modulos que el tenant no
/// tiene activos llegan marcados como inertes.
class DominioPermisos {
  final String dominio;
  final List<PermisoRol> permisos;

  const DominioPermisos({required this.dominio, required this.permisos});

  /// Lee el sobre completo: `{"dominios": [{dominio, permisos: [...]}]}`.
  static List<DominioPermisos> listaDesde(Map<String, dynamic> json) {
    return (json['dominios'] as List? ?? const [])
        .whereType<Map>()
        .map((d) {
          return DominioPermisos(
            dominio: d['dominio']?.toString() ?? '',
            permisos: (d['permisos'] as List? ?? const [])
                .whereType<Map>()
                .map((p) => PermisoRol.fromJson(Map<String, dynamic>.from(p)))
                .toList(),
          );
        })
        .toList();
  }
}

/// Rol tal como aparece asignado a un usuario (RF-14/RF-15).
class RolAsignado {
  final String id;
  final String nombre;
  final bool activo;
  final bool esSistema;

  const RolAsignado({
    required this.id,
    required this.nombre,
    required this.activo,
    required this.esSistema,
  });

  factory RolAsignado.fromJson(Map<String, dynamic> json) => RolAsignado(
    id: json['id']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? '',
    activo: json['activo'] == true,
    esSistema: json['es_sistema'] == true,
  );
}

/// Resultado del alta de un usuario (RF-05).
///
/// El token de activacion NO se persiste en claro: este es el unico momento en
/// que el backend puede entregarlo. Si se pierde, hay que reemitirlo.
class UsuarioCreado {
  final String id;
  final String correo;
  final String nombreCompleto;
  final String estado;
  final List<String> roles;

  /// Token de un solo uso, valido 24 horas.
  final String? tokenActivacion;

  const UsuarioCreado({
    required this.id,
    required this.correo,
    required this.nombreCompleto,
    required this.estado,
    required this.roles,
    this.tokenActivacion,
  });

  factory UsuarioCreado.fromJson(Map<String, dynamic> json) => UsuarioCreado(
    id: json['id']?.toString() ?? '',
    correo: json['correo']?.toString() ?? '',
    nombreCompleto: json['nombre_completo']?.toString() ?? '',
    estado: json['estado']?.toString() ?? '',
    roles: (json['roles'] as List? ?? const [])
        .map((r) => r.toString())
        .toList(),
    // El backend usa 'activacion_token' en el alta y 'verificacion_token'
    // cuando una edicion cambia el correo.
    tokenActivacion:
        json['activacion_token']?.toString() ??
        json['verificacion_token']?.toString(),
  );
}
