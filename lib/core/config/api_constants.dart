/// Configuracion de acceso al backend Django de NovaERP.
///
/// baseUrl y tenantSlug se inyectan en tiempo de compilacion para no tener que
/// tocar codigo al cambiar de entorno:
///
///   flutter run --dart-define-from-file=config/dev.json
///
/// 10.0.2.2 es el host de la maquina de desarrollo visto desde el emulador de
/// Android; en un dispositivo fisico hay que poner la IP de la LAN.
class ApiConstants {
  static const String _baseUrlCrudo = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  /// Base del API, siempre sin barra final: las rutas de abajo ya empiezan por
  /// '/', y dejar la barra produce URLs con '//' que confunden al depurar.
  static String get baseUrl => _baseUrlCrudo.endsWith('/')
      ? _baseUrlCrudo.substring(0, _baseUrlCrudo.length - 1)
      : _baseUrlCrudo;

  /// El backend es multi-tenant y exige el slug en el login. Se fija por
  /// compilacion: esta app se distribuye por empresa, asi que el usuario solo
  /// captura correo y contrasena.
  static const String tenantSlug = String.fromEnvironment(
    'TENANT_SLUG',
    defaultValue: 'demo',
  );

  // --- Autenticacion. El login es de dos fases: la contrasena solo devuelve
  // un reto de segundo factor; el token de sesion lo emite /otp/.
  static const String login = '/api/auth/login/';
  static const String otp = '/api/auth/otp/';
  static const String logout = '/api/auth/logout/';
  static const String recuperarPassword = '/api/auth/recuperar/';
  static const String restablecerPassword = '/api/auth/restablecer/';

  // --- Contexto del usuario autenticado: perfil, roles, permisos y modulos.
  static const String me = '/api/core/me/';

  // --- Sesiones propias (RF-19).
  static const String sesiones = '/api/core/sesiones/';
  static const String sesionesCerrarOtras = '/api/core/sesiones/cerrar-otras/';

  /// Ruta de una sesion concreta, por su jti (DELETE = logout remoto).
  static String sesion(String jti) => '/api/core/sesiones/$jti/';
}
