import 'dart:async';

class ApiClient {
  // Simulador de cliente HTTP (puedes implementar 'http' o 'dio' aquí en el futuro)
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulando retraso de red

    if (body['email'] == 'admin@novaerp.com' &&
        body['password'] == 'password123') {
      return {
        'success': true,
        'token': 'jwt_nova_erp_token_2026',
        'user': {
          'id': 'u101',
          'nombre': 'Usuario Administrador',
          'email': 'admin@novaerp.com',
          'rol': 'Admin',
        },
      };
    } else {
      throw Exception('Credenciales incorrectas');
    }
  }

  Future<void> get(String endpoint, {String? token}) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
