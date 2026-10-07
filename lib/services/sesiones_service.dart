import '../models/sesion.dart';

/// HU19 - Autogestion de sesiones propias. Solo exige sesion, no permisos:
/// el backend acota todo al usuario del JWT.
class SesionesService {
  /// GET [ApiConstants.sesiones]  ->  {results: [...]}
  Future<List<Sesion>> listar() async {
    // TODO(HU19): implementar.
    throw UnimplementedError('HU19: listar');
  }

  /// DELETE [ApiConstants.sesion] (jti)  ->  {revocada: bool}  (logout remoto)
  Future<bool> revocar(String jti) async {
    // TODO(HU19): implementar.
    throw UnimplementedError('HU19: revocar');
  }

  /// POST [ApiConstants.sesionesCerrarOtras]  ->  {revocadas: n}
  Future<int> cerrarOtras() async {
    // TODO(HU19): implementar.
    throw UnimplementedError('HU19: cerrarOtras');
  }
}
