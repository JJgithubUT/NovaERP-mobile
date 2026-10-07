import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistencia del JWT de sesion en el almacen seguro del sistema
/// (Keychain en iOS, EncryptedSharedPreferences en Android).
///
/// Solo se guarda el token de sesion emitido por la fase 2 del login. El reto
/// OTP intermedio NO se persiste: vive 5 minutos y solo en memoria, porque
/// acredita una fase de login a medias y no debe sobrevivir al proceso.
class TokenStorage {
  static const _claveToken = 'novaerp_session_token';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> leer() => _storage.read(key: _claveToken);

  Future<void> guardar(String token) =>
      _storage.write(key: _claveToken, value: token);

  Future<void> borrar() => _storage.delete(key: _claveToken);
}
