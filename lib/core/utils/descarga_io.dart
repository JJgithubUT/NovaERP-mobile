import 'package:share_plus/share_plus.dart';

import '../network/archivo_descargado.dart';

/// Movil y escritorio: abre la hoja de compartir con el archivo.
Future<void> guardarArchivo(ArchivoDescargado archivo) async {
  await Share.shareXFiles(
    [XFile.fromData(archivo.bytes, mimeType: archivo.tipo, name: archivo.nombre)],
    fileNameOverrides: [archivo.nombre],
  );
}
