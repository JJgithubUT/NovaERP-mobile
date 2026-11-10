import '../core/config/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/sesion.dart';

/// HU19 - Autogestion de sesiones propias. Solo exige sesion, no permisos:
/// el backend acota todo al usuario del JWT.
class SesionesService {
  final ApiClient _api = ApiClient.instancia;

  /// GET [ApiConstants.sesiones]  ->  {results: [...]}
  Future<List<Sesion>> listar() async {
    final respuesta = await _api.get(ApiConstants.sesiones);
    final resultados = respuesta['results'];
    if (resultados is! List) return const [];
    return resultados
        .whereType<Map<String, dynamic>>()
        .map(Sesion.fromJson)
        .toList();
  }

  /// DELETE [ApiConstants.sesion] (jti)  ->  {revocada: bool}  (logout remoto)
  Future<bool> revocar(String jti) async {
    final respuesta = await _api.delete(ApiConstants.sesion(jti));
    return respuesta['revocada'] == true;
  }

  /// POST [ApiConstants.sesionesCerrarOtras]  ->  {revocadas: n}
  Future<int> cerrarOtras() async {
    final respuesta = await _api.post(ApiConstants.sesionesCerrarOtras);
    final n = respuesta['revocadas'];
    return n is int ? n : int.tryParse(n?.toString() ?? '') ?? 0;
  }
}
