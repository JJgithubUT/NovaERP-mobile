import '../core/config/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/reto_login.dart';
import '../models/usuario.dart';

/// Autenticacion contra el backend. El login tiene dos fases y esta clase las
/// expone por separado porque entre una y otra hay interaccion del usuario
/// (teclear el codigo del autenticador).
///
/// REPARTO DEL SPRINT: cada HU implementa SOLO su bloque (los marcados con
/// "HUxx"). Los bloques estan separados a proposito para que los pull requests
/// no se pisen. No muevas ni reordenes metodos ajenos.
class AuthService {
  final ApiClient _api = ApiClient.instancia;

  // ===================================================================
  // BASE (ya hecho): fase 1 del login y contexto de la sesion.
  // ===================================================================

  /// FASE 1: valida la contrasena. No inicia sesion; devuelve el reto de
  /// segundo factor. El tenant no lo elige el usuario: viene de la compilacion.
  Future<RetoLogin> iniciarSesion(String correo, String password) async {
    final respuesta = await _api.post(ApiConstants.login, {
      'tenant_slug': ApiConstants.tenantSlug,
      'correo': correo,
      'password': password,
    });
    return RetoLogin.fromJson(respuesta);
  }

  /// Perfil, roles, permisos efectivos y modulos activos del usuario en curso.
  Future<ContextoSesion> obtenerContexto() async {
    final respuesta = await _api.get(ApiConstants.me);
    return ContextoSesion.fromJson(respuesta);
  }

  // ===================================================================
  // HU16 - Autenticacion multifactor (MFA/TOTP)
  // ===================================================================

  /// FASE 2: valida el codigo TOTP contra el reto y devuelve el JWT de sesion.
  ///
  /// POST [ApiConstants.otp]  body: {reto, codigo}  ->  {token}
  /// Un codigo incorrecto cuenta en el mismo contador de intentos fallidos que
  /// la contrasena, asi que insistir aqui puede bloquear la cuenta.
  Future<String> validarOtp(String reto, String codigo) async {
    // TODO(HU16): implementar.
    throw UnimplementedError('HU16: validarOtp');
  }

  // ===================================================================
  // HU17 - Cierre de sesion explicito (Logout)
  // ===================================================================

  /// Revoca la sesion en curso del lado servidor. Es idempotente.
  ///
  /// POST [ApiConstants.logout]  (requiere Bearer)  ->  200
  Future<void> cerrarSesion() async {
    // TODO(HU17): implementar.
    throw UnimplementedError('HU17: cerrarSesion');
  }

  // ===================================================================
  // HU18 - Recuperacion y restablecimiento de contrasena
  // ===================================================================

  /// Dispara el correo de recuperacion. El backend responde igual exista o no
  /// la cuenta, para no revelar que correos estan dados de alta.
  ///
  /// POST [ApiConstants.recuperarPassword]  body: {tenant_slug, correo}
  Future<void> recuperarPassword(String correo) async {
    // TODO(HU18): implementar.
    throw UnimplementedError('HU18: recuperarPassword');
  }

  /// Consume el token de un solo uso (1 h de vigencia) y fija la nueva
  /// contrasena. Token vencido o ya usado -> 422 con el mismo mensaje.
  /// Al terminar, el backend invalida TODAS las sesiones previas del usuario.
  ///
  /// POST [ApiConstants.restablecerPassword]  body: {token, password}
  Future<void> restablecerPassword(String token, String password) async {
    // TODO(HU18): implementar.
    throw UnimplementedError('HU18: restablecerPassword');
  }
}
