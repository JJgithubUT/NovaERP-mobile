/// Error de API ya traducido a algo que la UI puede mostrar.
///
/// El backend usa un vocabulario de errores estable que conviene distinguir:
///   400 -> parametro mal formado          {detail|mensaje, campo?}
///   401 -> sin sesion o sesion expirada   {detail|mensaje}
///   403 -> falta un permiso               {detail, permiso_requerido}
///   404 -> no encontrado                  {detail}
///   422 -> regla de negocio violada       {detail, campo?, ...extra}
class ApiException implements Exception {
  final int? statusCode;
  final String mensaje;

  /// Campo del formulario en conflicto, cuando el backend lo senala (400/422).
  final String? campo;

  /// Codigo de permiso que faltaba (403). Util para el mensaje y para depurar
  /// que permiso hay que darle al rol.
  final String? permisoRequerido;

  const ApiException({
    required this.mensaje,
    this.statusCode,
    this.campo,
    this.permisoRequerido,
  });

  /// La sesion ya no sirve: hay que volver al login.
  bool get esSesionInvalida => statusCode == 401;

  /// Autenticado, pero sin el permiso necesario.
  bool get esPermisoDenegado => statusCode == 403;

  /// Regla de negocio: el formulario esta bien formado pero el dominio lo rechaza.
  bool get esReglaDeNegocio => statusCode == 422;

  /// No se pudo hablar con el servidor (sin red, timeout, host caido).
  bool get esErrorDeRed => statusCode == null;

  @override
  String toString() => mensaje;
}
