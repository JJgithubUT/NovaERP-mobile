import '../core/config/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/paginado.dart';
import '../models/personal.dart';

/// Gestion de usuarios (EP01: RF-05..RF-09) y de roles (EP02: RF-10..RF-13)
/// del tenant.
///
/// REPARTO DEL SPRINT: cada HU implementa SOLO su bloque (los marcados con
/// "HUxx"). Los bloques estan separados a proposito para que los pull requests
/// no se pisen. No muevas ni reordenes metodos ajenos.
class PersonalService {
  final ApiClient _api = ApiClient.instancia;

  // ===================================================================
  // BASE (ya hecho): catalogo de roles para los selectores.
  // ===================================================================

  /// Roles del tenant, paginados. [activo] filtra por estado (null = todos).
  Future<Paginado<Rol>> roles({
    int pagina = 1,
    String? busqueda,
    bool? activo,
  }) async {
    final json = await _api.get(
      ApiConstants.roles,
      query: _consulta({
        'page': pagina,
        'search': busqueda,
        'activo': activo?.toString(),
      }),
    );
    return Paginado.fromJson(json, Rol.fromJson);
  }

  /// Todos los roles activos, para los selectores de asignacion.
  Future<List<Rol>> rolesActivos() async {
    final acumulados = <Rol>[];
    var pagina = 1;
    while (true) {
      final lote = await roles(pagina: pagina);
      acumulados.addAll(lote.elementos.where((r) => r.activo));
      if (!lote.hayMasPaginas) break;
      pagina++;
    }
    return acumulados;
  }

  /// Catalogo maestro de permisos agrupado por dominio. Es el origen del
  /// selector al crear o editar un rol: solo se pueden elegir permisos de aqui.
  /// Los de modulos que el tenant no tiene activos llegan como `inerte`.
  Future<List<DominioPermisos>> catalogoPermisos() async {
    final json = await _api.get(ApiConstants.permisos);
    return DominioPermisos.listaDesde(json);
  }

  /// Roles (con su id) de un usuario, a partir de los NOMBRES que trae el
  /// directorio. No existe un endpoint para consultar los roles de un usuario,
  /// asi que se cruzan con el catalogo de roles del tenant; el nombre de un rol
  /// es unico dentro de la empresa.
  Future<List<RolAsignado>> resolverRoles(List<String> nombres) async {
    if (nombres.isEmpty) return const [];
    final buscados = nombres.toSet();
    final encontrados = <RolAsignado>[];
    var pagina = 1;
    while (true) {
      final lote = await roles(pagina: pagina);
      for (final r in lote.elementos) {
        if (buscados.contains(r.nombre)) {
          encontrados.add(
            RolAsignado(
              id: r.id,
              nombre: r.nombre,
              activo: r.activo,
              esSistema: r.esSistema,
            ),
          );
        }
      }
      if (!lote.hayMasPaginas) break;
      pagina++;
    }
    encontrados.sort((a, b) => a.nombre.compareTo(b.nombre));
    return encontrados;
  }

  // ===================================================================
  // HU05 - Registrar usuario dentro del tenant
  // ===================================================================

  /// Alta de usuario. Nace en estado 'pendiente' y sin contrasena: solo puede
  /// fijarla consumiendo el token de activacion que devuelve esta llamada.
  ///
  /// POST [ApiConstants.usuarios]
  ///   body: {correo, nombre_completo, telefono?, puesto?, departamento?, roles}
  Future<UsuarioCreado> crearUsuario({
    required String correo,
    required String nombreCompleto,
    String? telefono,
    String? puesto,
    String? departamento,
    List<String> rolesIds = const [],
  }) async {
    final json = await _api.post(ApiConstants.usuarios, {
      'correo': correo,
      'nombre_completo': nombreCompleto,
      if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
      if (puesto != null && puesto.isNotEmpty) 'puesto': puesto,
      if (departamento != null && departamento.isNotEmpty)
        'departamento': departamento,
      if (rolesIds.isNotEmpty) 'roles': rolesIds,
    });
    return UsuarioCreado.fromJson(json);
  }

  // ===================================================================
  // HU06 - Consultar directorio de usuarios
  // ===================================================================

  /// Directorio paginado. Busca en nombre, correo y puesto.
  ///
  /// GET [ApiConstants.usuarios]
  ///   query: page, search, estado, departamento, rol, orden, desc
  /// El backend aplica solo el filtro de tenant.
  Future<Paginado<UsuarioDirectorio>> usuarios({
    int pagina = 1,
    String? busqueda,
    String? estado,
    String? departamento,
    String? rolId,
    String orden = 'nombre',
    bool descendente = false,
  }) async {
    final json = await _api.get(
      ApiConstants.usuarios,
      query: _consulta({
        'page': pagina,
        'search': busqueda,
        'estado': estado,
        'departamento': departamento,
        'rol': rolId,
        'orden': orden,
        if (descendente) 'desc': 'true',
      }),
    );
    return Paginado.fromJson(json, UsuarioDirectorio.fromJson);
  }

  // ===================================================================
  // HU07 - Editar usuario
  // ===================================================================

  /// Edicion parcial de datos del usuario. Cambiar el correo devuelve un nuevo
  /// token, esta vez de verificacion.
  ///
  /// PATCH [ApiConstants.usuarios]{id}/   body: solo los campos que cambian
  Future<UsuarioCreado> editarUsuario(
    String id,
    Map<String, dynamic> cambios,
  ) async {
    final json = await _api.patch('${ApiConstants.usuarios}$id/', cambios);
    return UsuarioCreado.fromJson(json);
  }

  // ===================================================================
  // HU08 - Suspender o reactivar usuario
  // ===================================================================

  /// Suspende al usuario: cierra sus sesiones y bloquea su login.
  ///
  /// POST [ApiConstants.usuarios]{id}/suspender/
  Future<void> suspender(String id) async {
    await _api.post('${ApiConstants.usuarios}$id/suspender/');
  }

  /// Reactiva a un usuario suspendido, conservando sus roles.
  ///
  /// POST [ApiConstants.usuarios]{id}/reactivar/
  Future<void> reactivar(String id) async {
    await _api.post('${ApiConstants.usuarios}$id/reactivar/');
  }

  // ===================================================================
  // HU14 - Vincular roles a un usuario
  // ===================================================================

  /// Asigna uno o varios roles ACTIVOS del tenant a un usuario. Devuelve la
  /// lista resultante de roles del usuario.
  ///
  /// POST [ApiConstants.usuarios]{id}/roles/   body: {roles: [rolId, ...]}
  /// 422 si algun rol no existe, es de otro tenant o esta inactivo, y 422
  /// "El rol Auditor es incompatible con permisos de creacion, edicion o
  /// eliminacion." si el conjunto resultante mezcla auditoria con mutacion
  /// (campo 'roles'). Asignar un rol que ya tiene no falla ni duplica.
  Future<List<RolAsignado>> asignarRoles(
    String usuarioId,
    List<String> rolesIds,
  ) async {
    final json = await _api.post('${ApiConstants.usuarios}$usuarioId/roles/', {
      'roles': rolesIds,
    });
    return RolAsignado.listaDesde(json);
  }

  // ===================================================================
  // HU15 - Retirar rol a un usuario
  // ===================================================================

  /// Retira un rol a un usuario. Devuelve la lista resultante de roles.
  ///
  /// DELETE [ApiConstants.usuarios]{id}/roles/{rolId}/
  /// 422 "El usuario debe conservar al menos un rol." si era el unico, y 422
  /// "No puede revocar este rol: es el unico administrador activo del tenant."
  /// si es TENANT_ADMIN y no hay otro administrador activo (campo 'rol_id').
  Future<List<RolAsignado>> revocarRol(String usuarioId, String rolId) async {
    final json = await _api.delete(
      '${ApiConstants.usuarios}$usuarioId/roles/$rolId/',
    );
    return RolAsignado.listaDesde(json);
  }

  // ===================================================================
  // HU10 - Crear rol de trabajo
  // ===================================================================

  /// Alta de un rol personalizado con permisos del catalogo maestro.
  ///
  /// POST [ApiConstants.roles]   body: {nombre, permisos: [codigo, ...]}
  /// 422 si el nombre ya existe en el tenant (campo 'nombre') o si no hay al
  /// menos un permiso (campo 'permisos').
  Future<Rol> crearRol({
    required String nombre,
    required Set<String> permisos,
  }) async {
    final json = await _api.post(ApiConstants.roles, {
      'nombre': nombre,
      'permisos': permisos.toList(),
    });
    return Rol.fromJson(json);
  }

  // ===================================================================
  // HU12 - Modificar permisos de un rol existente
  // ===================================================================

  /// Edicion parcial de un rol: nombre y/o conjunto COMPLETO de permisos.
  /// El conjunto de permisos se reemplaza entero, no se parcha.
  ///
  /// PATCH [ApiConstants.roles]{id}/   body: {nombre?, permisos?, activo?}
  /// 403 "Este rol de sistema no puede modificarse." sobre TENANT_ADMIN.
  Future<Rol> editarRol(String id, Map<String, dynamic> cambios) async {
    final json = await _api.patch('${ApiConstants.roles}$id/', cambios);
    return Rol.fromJson(json);
  }

  // ===================================================================
  // HU13 - Eliminar o desactivar un rol personalizado
  // ===================================================================

  /// Baja logica de un rol (nunca hay borrado fisico).
  ///
  /// DELETE [ApiConstants.roles]{id}/                    -> si no tiene usuarios
  /// DELETE [ApiConstants.roles]{id}/?desactivar=true    -> con usuarios, tras
  ///   confirmar. Sin la bandera y con usuarios asignados responde 422
  ///   "Este rol tiene N usuarios asignados..." (campo 'rol').
  /// 403 sobre TENANT_ADMIN.
  Future<void> desactivarRol(String id, {bool confirmado = false}) async {
    final sufijo = confirmado ? '?desactivar=true' : '';
    await _api.delete('${ApiConstants.roles}$id/$sufijo');
  }

  /// Reactiva un rol dado de baja, para poder asignarlo de nuevo.
  ///
  /// PATCH [ApiConstants.roles]{id}/   body: {activo: true}
  Future<void> reactivarRol(String id) async {
    await _api.patch('${ApiConstants.roles}$id/', {'activo': true});
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
}
