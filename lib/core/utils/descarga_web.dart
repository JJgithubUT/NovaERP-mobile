import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../network/archivo_descargado.dart';

/// Web: baja el archivo con un enlace temporal, como cualquier descarga.
Future<void> guardarArchivo(ArchivoDescargado archivo) async {
  final blob = web.Blob(
    [archivo.bytes.toJS].toJS,
    web.BlobPropertyBag(type: archivo.tipo),
  );
  final url = web.URL.createObjectURL(blob);
  final enlace = web.HTMLAnchorElement()
    ..href = url
    ..download = archivo.nombre;
  web.document.body?.append(enlace);
  enlace.click();
  enlace.remove();
  web.URL.revokeObjectURL(url);
}
