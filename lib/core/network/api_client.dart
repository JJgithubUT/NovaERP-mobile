import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/api_constants.dart';
import 'api_exception.dart';
import 'archivo_descargado.dart';
import 'token_storage.dart';

/// Cliente HTTP unico de la app.
///
/// Concentra tres cosas que si no acaban repetidas en cada servicio:
///   1. la inyeccion del `Authorization: Bearer <jwt>` en cada peticion;
///   2. la traduccion de las respuestas de error del backend a ApiException;
///   3. la deteccion del 401 (sesion revocada o expirada), que notifica una
///      sola vez al AuthProvider para que devuelva al usuario al login.
///
/// El backend revoca sesiones del lado servidor (RF-17/RF-19), asi que un token
/// que ayer valia puede responder 401 hoy aunque el JWT no haya expirado: por
/// eso el 401 se maneja de forma central y no endpoint por endpoint.
class ApiClient {
  ApiClient._interno() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
        // Los codigos de error se manejan aqui, en el catch de DioException;
        // dejamos que Dio lance para no tener dos caminos de error.
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Los endpoints publicos (login, otp, recuperar) no llevan token: si
          // se enviara uno caducado, el middleware lo ignoraria igualmente,
          // pero mandarlo confunde la bitacora.
          if (!_esEndpointPublico(options.path)) {
            final token = await _tokenStorage.leer();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient instancia = ApiClient._interno();

  late final Dio _dio;
  final TokenStorage _tokenStorage = TokenStorage();

  /// Lo fija AuthProvider al arrancar. Se dispara cuando el backend responde
  /// 401 a una peticion autenticada, para limpiar la sesion local y navegar al
  /// login sin que cada pantalla tenga que preverlo.
  void Function()? onSesionInvalida;

  static const _endpointsPublicos = [
    ApiConstants.login,
    ApiConstants.otp,
    ApiConstants.recuperarPassword,
    ApiConstants.restablecerPassword,
  ];

  bool _esEndpointPublico(String path) => _endpointsPublicos.contains(path);

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? query,
  }) async {
    return _ejecutar(() => _dio.get(endpoint, queryParameters: query));
  }

  Future<Map<String, dynamic>> post(
    String endpoint, [
    Map<String, dynamic>? body,
  ]) async {
    return _ejecutar(() => _dio.post(endpoint, data: body ?? const {}));
  }

  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return _ejecutar(() => _dio.patch(endpoint, data: body));
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    return _ejecutar(() => _dio.delete(endpoint));
  }

  /// Descarga un archivo (CSV, PDF...) en lugar de un objeto JSON.
  ///
  /// [nombreBase] es el nombre sugerido sin extension: el backend lo manda en
  /// `Content-Disposition`, pero en web ese encabezado no es legible desde otro
  /// origen, asi que la extension se deduce del tipo de contenido.
  ///
  /// [espera] es el tiempo maximo de respuesta. Es mayor que el de las demas
  /// peticiones (20 s) porque el backend genera el archivo de forma sincrona: un
  /// PDF de miles de filas tarda decenas de segundos y, si el cliente se rinde
  /// antes, el backend ya habria registrado la exportacion sin entregar nada.
  ///
  /// Se sube TAMBIEN `connectTimeout`: en web el navegador no distingue "conectar"
  /// de "esperar la primera respuesta" (un GET sin cuerpo no reporta progreso
  /// hasta recibir las cabeceras), asi que el adaptador de Dio abortaria a los
  /// 15 s del `connectTimeout` general mientras el backend aun arma el archivo.
  /// En movil y escritorio ese tiempo solo cubre la conexion TCP.
  Future<ArchivoDescargado> descargar(
    String endpoint, {
    Map<String, dynamic>? query,
    String nombreBase = 'archivo',
    Duration espera = const Duration(minutes: 3),
  }) async {
    try {
      final respuesta = await _dio.get<List<int>>(
        endpoint,
        queryParameters: query,
        options: Options(
          responseType: ResponseType.bytes,
          connectTimeout: espera,
          receiveTimeout: espera,
        ),
      );
      final tipo = respuesta.headers.value('content-type') ?? 'application/octet-stream';
      final extension = tipo.contains('pdf')
          ? 'pdf'
          : tipo.contains('csv')
          ? 'csv'
          : 'bin';
      return ArchivoDescargado(
        bytes: Uint8List.fromList(respuesta.data ?? const []),
        nombre: '$nombreBase.$extension',
        tipo: tipo.split(';').first,
      );
    } on DioException catch (e) {
      // Con responseType bytes, el cuerpo de un error tambien llega en bytes:
      // se decodifica para que _traducir lea el {detail} de siempre.
      final cuerpo = e.response?.data;
      if (cuerpo is List<int>) {
        try {
          e.response!.data = jsonDecode(utf8.decode(cuerpo));
        } catch (_) {
          // No era JSON: se deja como esta.
        }
      }
      throw _traducir(e);
    }
  }

  Future<Map<String, dynamic>> _ejecutar(
    Future<Response> Function() peticion,
  ) async {
    try {
      final respuesta = await peticion();
      final datos = respuesta.data;
      if (datos is Map<String, dynamic>) return datos;
      // Todos los endpoints del backend devuelven un objeto JSON (las listas
      // van dentro del sobre {count, results, ...}). Un cuerpo vacio, como el
      // de un DELETE 204, se normaliza a mapa vacio.
      return const {};
    } on DioException catch (e) {
      throw _traducir(e);
    }
  }

  ApiException _traducir(DioException e) {
    final status = e.response?.statusCode;

    if (status == null) {
      // Sin respuesta HTTP no hay nada que traducir del backend, asi que el
      // mensaje tiene que valerse solo. Se nombra la URL: la causa mas comun
      // es apuntar a un host equivocado (10.0.2.2 sirve para el emulador de
      // Android pero no para escritorio, y viceversa), y sin verla escrita no
      // hay forma de darse cuenta.
      // La URI que Dio resolvio de verdad, no una concatenacion a mano: si la
      // base y la ruta se unen mal, se quiere ver el resultado real.
      final destino = e.requestOptions.uri;
      final detalle = switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'El servidor no respondió a tiempo.',
        DioExceptionType.connectionError =>
          'No se pudo establecer la conexión.',
        DioExceptionType.badCertificate =>
          'El certificado del servidor no es válido.',
        DioExceptionType.cancel => 'La petición se canceló.',
        _ => e.message ?? 'Error de red.',
      };

      return ApiException(mensaje: '$detalle\n\nDestino: $destino');
    }

    if (status == 401) {
      // Solo cierra sesion si habia una: un 401 de /login/ es "credenciales
      // incorrectas", no una sesion caduca, y no debe disparar el logout.
      if (!_esEndpointPublico(e.requestOptions.path)) {
        onSesionInvalida?.call();
      }
    }

    final cuerpo = e.response?.data;
    if (cuerpo is! Map) {
      return ApiException(
        statusCode: status,
        mensaje: 'El servidor respondio con un error ($status).',
      );
    }

    // El backend usa 'detail' en las vistas de recursos y 'mensaje' en las de
    // autenticacion; se aceptan las dos.
    final mensaje = (cuerpo['detail'] ?? cuerpo['mensaje'])?.toString();

    return ApiException(
      statusCode: status,
      mensaje: mensaje ?? 'El servidor respondio con un error ($status).',
      campo: cuerpo['campo']?.toString(),
      permisoRequerido: cuerpo['permiso_requerido']?.toString(),
    );
  }
}
