import 'dart:typed_data';

/// Archivo recibido del backend (por ejemplo la bitacora exportada a CSV o PDF).
class ArchivoDescargado {
  const ArchivoDescargado({
    required this.bytes,
    required this.nombre,
    required this.tipo,
  });

  final Uint8List bytes;

  /// Nombre sugerido, con extension.
  final String nombre;

  /// Tipo MIME (`text/csv`, `application/pdf`...).
  final String tipo;
}
