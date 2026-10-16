import 'package:flutter/foundation.dart';

import '../core/auth/permisos.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/network/token_storage.dart';
import '../models/reto_login.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';

/// Fases por las que pasa la sesion. El login del backend no es un paso sino
/// dos, asi que un simple booleano `isAuthenticated` no alcanza para describirlo.
enum EstadoSesion {
  /// Arranque: aun no sabemos si hay una sesion guardada que siga viva.
  comprobando,

  /// Sin sesion. Toca capturar correo y contrasena.
  sinSesion,

  /// Contrasena aceptada; falta el codigo del segundo factor.
  esperandoOtp,

  /// Contrasena aceptada y el usuario aun no tiene MFA: hay que mostrarle el
  /// secreto/QR antes de pedirle el primer codigo.
  enrolandoMfa,

  /// Sesion completa y contexto cargado.
  activa,
}

/// Estado de autenticacion y fuente unica de verdad sobre lo que el usuario
/// puede hacer en la interfaz.
class AuthProvider with ChangeNotifier {
  AuthProvider() {
    // El 401 puede llegar en cualquier peticion (el backend revoca sesiones del
    // lado servidor), asi que la limpieza se centraliza aqui.
    ApiClient.instancia.onSesionInvalida = _limpiarSesionLocal;
  }

  final AuthService _authService = AuthService();
  final TokenStorage _tokenStorage = TokenStorage();

  EstadoSesion _estado = EstadoSesion.comprobando;
  ContextoSesion? _contexto;
  RetoLogin? _reto;
  bool _cargando = false;
  String? _error;

  EstadoSesion get estado => _estado;
  ContextoSesion? get contexto => _contexto;
  Usuario? get usuario => _contexto?.usuario;
  RetoLogin? get reto => _reto;
  bool get cargando => _cargando;
  String? get error => _error;

  bool get estaAutenticado => _estado == EstadoSesion.activa;

  // ------------------------------------------------------------- permisos
  //
  // La UI pregunta por permiso, nunca por nombre de rol: es el mismo criterio
  // con el que autoriza el backend. Ver core/auth/permisos.dart.

  bool get esAdmin => _contexto?.esAdmin ?? false;

  bool puede(String codigo) => _contexto?.puede(codigo) ?? false;

  bool puedeAlguno(List<String> codigos) =>
      _contexto?.puedeAlguno(codigos) ?? false;

  bool get veInventario => puedeAlguno(Permisos.puertaInventario);
  bool get veReportes => puedeAlguno(Permisos.puertaReportes);
  bool get vePersonal => puedeAlguno(Permisos.puertaPersonal);

  // ------------------------------------------------------------ ciclo de vida

  /// Reanuda la sesion guardada, si la hay. Se llama una vez al arrancar.
  ///
  /// Valida el token contra `/me/` en vez de confiar en su fecha de expiracion:
  /// el backend puede haberla revocado (logout remoto, suspension del usuario,
  /// cierre de sesiones por el admin) sin que el JWT haya caducado.
  Future<void> inicializar() async {
    final token = await _tokenStorage.leer();
    if (token == null) {
      _fijarEstado(EstadoSesion.sinSesion);
      return;
    }

    try {
      _contexto = await _authService.obtenerContexto();
      _fijarEstado(EstadoSesion.activa);
    } on ApiException {
      // Sesion revocada, expirada o servidor inalcanzable: en cualquiera de los
      // casos no podemos entrar, y el token que no sirve no debe quedarse.
      await _tokenStorage.borrar();
      _contexto = null;
      _fijarEstado(EstadoSesion.sinSesion);
    }
  }

  /// FASE 1 del login. Devuelve true si la contrasena fue aceptada y ya hay un
  /// reto de segundo factor pendiente.
  Future<bool> iniciarSesion(String correo, String password) async {
    _empezarCarga();
    try {
      _reto = await _authService.iniciarSesion(correo, password);
      _fijarEstado(
        _reto!.requiereEnrolamiento
            ? EstadoSesion.enrolandoMfa
            : EstadoSesion.esperandoOtp,
      );
      _cargando = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _fallar(e.mensaje);
      return false;
    }
  }

  // ===================================================================
  // HU16 - Autenticacion multifactor (MFA/TOTP)
  // ===================================================================

  /// FASE 2 del login: valida el codigo TOTP, guarda el token y carga el
  /// contexto (perfil, roles, permisos, modulos).
  ///
  /// Guia: tomar el reto de [_reto], llamar a AuthService.validarOtp, guardar
  /// el token con [_tokenStorage], cargar el contexto con
  /// AuthService.obtenerContexto y pasar a [EstadoSesion.activa]. Ante un
  /// ApiException usar [_fallar] y devolver false.
  Future<bool> validarOtp(String codigo) async {
    final reto = _reto;
    if (reto == null) {
      _fallar('La sesion de ingreso expiro. Vuelva a iniciar sesion.');
      return false;
    }

    _empezarCarga();
    try {
      final token = await _authService.validarOtp(reto.reto, codigo);
      await _tokenStorage.guardar(token);

      _contexto = await _authService.obtenerContexto();
      _reto = null;
      _cargando = false;
      _fijarEstado(EstadoSesion.activa);
      return true;
    } on ApiException catch (e) {
      _fallar(e.mensaje);
      return false;
    }
  }

  /// Vuelve del paso de OTP a la pantalla de credenciales. Descarta el reto:
  /// no sirve de nada conservarlo, y con el secreto de enrolamiento a la vista
  /// es preferible no dejarlo en memoria.
  void cancelarReto() {
    _reto = null;
    _error = null;
    _fijarEstado(EstadoSesion.sinSesion);
  }

  /// El usuario ya guardo su secreto en la app autenticadora y va a teclear su
  /// primer codigo. El reto sigue siendo el mismo; solo cambia la pantalla.
  void confirmarEnrolamiento() {
    if (_estado != EstadoSesion.enrolandoMfa) return;
    _error = null;
    _fijarEstado(EstadoSesion.esperandoOtp);
  }

  // ===================================================================
  // HU17 - Cierre de sesion explicito (Logout)
  // ===================================================================

  /// Cierra la sesion: revoca en el servidor y limpia el dispositivo.
  ///
  /// Guia: llamar a AuthService.cerrarSesion; si el servidor no responde, cerrar
  /// igual del lado del dispositivo (dejar al usuario dentro por falta de red
  /// seria peor). Terminar con [_limpiarSesionLocalAsync]; AuthGate lleva solo
  /// al login.
  Future<void> cerrarSesion() async {
    // TODO(HU17): implementar.
    throw UnimplementedError('HU17: AuthProvider.cerrarSesion');
  }

  // ===================================================================
  // BASE (ya hecho)
  // ===================================================================

  void limpiarError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  // ------------------------------------------------------------------ interno

  void _limpiarSesionLocal() {
    // Version sincrona para el interceptor del 401: el borrado del token corre
    // en segundo plano y el estado se actualiza ya.
    _tokenStorage.borrar();
    _contexto = null;
    _reto = null;
    _fijarEstado(EstadoSesion.sinSesion);
  }

  // ignore: unused_element -- lo usa cerrarSesion (HU17)
  Future<void> _limpiarSesionLocalAsync() async {
    await _tokenStorage.borrar();
    _contexto = null;
    _reto = null;
    _fijarEstado(EstadoSesion.sinSesion);
  }

  void _empezarCarga() {
    _cargando = true;
    _error = null;
    notifyListeners();
  }

  void _fallar(String mensaje) {
    _cargando = false;
    _error = mensaje;
    notifyListeners();
  }

  void _fijarEstado(EstadoSesion nuevo) {
    _estado = nuevo;
    notifyListeners();
  }
}
