/// Resultado de la fase 1 del login (contrasena validada).
///
/// El backend nunca emite el token de sesion aqui: devuelve un reto efimero
/// (JWT de 5 minutos) que solo acredita que la contrasena era correcta. El
/// token real se obtiene en la fase 2, al validar el codigo TOTP.
class RetoLogin {
  /// Token de reto que hay que devolver en `POST /api/auth/otp/`.
  final String reto;

  /// El backend responde mfa:"enroll" cuando el usuario aun no tiene segundo
  /// factor configurado (primer acceso, o tras un reset de MFA del admin).
  final bool requiereEnrolamiento;

  /// Secreto TOTP en claro. El backend lo entrega UNA SOLA VEZ, junto con el
  /// reto de enrolamiento: si se pierde, el usuario necesita que un admin le
  /// resetee el MFA. Nulo cuando el usuario ya estaba enrolado.
  final String? secreto;

  /// URI otpauth:// lista para pintarse como codigo QR.
  final String? otpauthUri;

  final String mensaje;

  const RetoLogin({
    required this.reto,
    required this.requiereEnrolamiento,
    required this.mensaje,
    this.secreto,
    this.otpauthUri,
  });

  factory RetoLogin.fromJson(Map<String, dynamic> json) {
    return RetoLogin(
      reto: json['reto']?.toString() ?? '',
      requiereEnrolamiento: json['mfa']?.toString() == 'enroll',
      secreto: json['secret']?.toString(),
      otpauthUri: json['otpauth_uri']?.toString(),
      mensaje: json['mensaje']?.toString() ?? '',
    );
  }
}
