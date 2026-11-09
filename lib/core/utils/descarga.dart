// Entrega al usuario un archivo descargado: en la web lo baja por el
// navegador; en movil abre la hoja de compartir del sistema.
//
// El archivo `descarga_web.dart` se usa solo en web y `descarga_io.dart` en el
// resto de plataformas; ambos exponen la misma funcion `guardarArchivo`.
export 'descarga_io.dart' if (dart.library.js_interop) 'descarga_web.dart';
