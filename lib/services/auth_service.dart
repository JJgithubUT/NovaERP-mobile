import '../core/config/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/reto_login.dart';
import '../models/usuario.dart';

/// Autenticacion contra el backend (RF-16). El login tiene dos fases y esta
/// clase las expone por separado porque entre una y otra hay interaccion del
/// usuario (teclear el codigo del autenticador).
class AuthService {
  final ApiClient _api = ApiClient.instancia;

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

  /// FASE 2: valida el codigo TOTP contra el reto y devuelve el JWT de sesion.
  ///
  /// Un codigo incorrecto cuenta en el mismo contador de intentos fallidos que
  /// la contrasena, asi que insistir aqui puede bloquear la cuenta.
  Future<String> validarOtp(String reto, String codigo) async {
    final respuesta = await _api.post(ApiConstants.otp, {
      'reto': reto,
      'codigo': codigo,
    });
    final token = respuesta['token']?.toString();
    if (token == null || token.isEmpty) {
      throw StateError('El servidor no devolvio un token de sesion.');
    }
    return token;
  }

  /// Perfil, roles, permisos efectivos y modulos activos del usuario en curso.
  Future<ContextoSesion> obtenerContexto() async {
    final respuesta = await _api.get(ApiConstants.me);
    return ContextoSesion.fromJson(respuesta);
  }

  /// Revoca la sesion en curso del lado servidor. Es idempotente.
  Future<void> cerrarSesion() async {
    await _api.post(ApiConstants.logout);
  }

  /// Dispara el correo de recuperacion. El backend responde igual exista o no
  /// la cuenta, para no revelar que correos estan dados de alta.
  Future<void> recuperarPassword(String correo) async {
    await _api.post(ApiConstants.recuperarPassword, {
      'tenant_slug': ApiConstants.tenantSlug,
      'correo': correo,
    });
  }

  /// Consume el token de un solo uso (1 h de vigencia) y fija la nueva
  /// contrasena. Token vencido o ya usado -> 422 con el mismo mensaje.
  /// Al terminar, el backend invalida TODAS las sesiones previas del usuario.
  Future<void> restablecerPassword(String token, String password) async {
    await _api.post(ApiConstants.restablecerPassword, {
      'token': token,
      'password': password,
    });
  }
}
