import 'package:novaerpmobile/core/network/api_client.dart';
import 'package:novaerpmobile/core/config/api_constants.dart';
import 'package:novaerpmobile/models/usuario.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.post(ApiConstants.loginEndpoint, {
        'email': email,
        'password': password,
      });

      return {
        'token': response['token'],
        'usuario': Usuario.fromJson(response['user']),
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _apiClient.get(ApiConstants.logoutEndpoint);
  }
}
