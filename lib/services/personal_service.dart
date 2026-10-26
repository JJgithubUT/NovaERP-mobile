import '../core/config/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/paginado.dart';
import '../models/personal.dart';

/// Gestion de usuarios del tenant (EP01: RF-05..RF-09).
///
/// REPARTO DEL SPRINT: cada HU implementa SOLO su bloque (los marcados con
/// "HUxx"). Los bloques estan separados a proposito para que los pull requests
/// no se pisen. No muevas ni reordenes metodos ajenos.
class PersonalService {
  final ApiClient _api = ApiClient.instancia;

  // ===================================================================
  // BASE (ya hecho): catalogo de roles para los selectores.
  // ===================================================================

  Future<Paginado<Rol>> roles({int pagina = 1, String? busqueda}) async {
    final json = await _api.get(
      ApiConstants.roles,
      query: _consulta({'page': pagina, 'search': busqueda}),
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
    // TODO(HU06): implementar.
    throw UnimplementedError('HU06: PersonalService.usuarios');
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
    // TODO(HU07): implementar.
    throw UnimplementedError('HU07: PersonalService.editarUsuario');
  }

  // ===================================================================
  // HU08 - Suspender o reactivar usuario
  // ===================================================================

  /// Suspende al usuario: cierra sus sesiones y bloquea su login.
  ///
  /// POST [ApiConstants.usuarios]{id}/suspender/
  Future<void> suspender(String id) async {
    // TODO(HU08): implementar.
    throw UnimplementedError('HU08: PersonalService.suspender');
  }

  /// Reactiva a un usuario suspendido, conservando sus roles.
  ///
  /// POST [ApiConstants.usuarios]{id}/reactivar/
  Future<void> reactivar(String id) async {
    // TODO(HU08): implementar.
    throw UnimplementedError('HU08: PersonalService.reactivar');
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
