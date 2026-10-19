/// Formateo de los valores que el backend entrega como cadena.
///
/// Los decimales viajan en texto a proposito ("850.0000", "10.000") para no
/// perder precision al pasar por JSON. Aqui solo se les da forma para mostrar;
/// no se hace aritmetica con ellos.
class Formato {
  /// Cantidad de inventario: quita los ceros de relleno ("10.000" -> "10",
  /// "2.500" -> "2.5") y agrupa los miles.
  static String cantidad(String? valor) {
    final numero = double.tryParse(valor ?? '');
    if (numero == null) return valor ?? '—';

    final texto = numero
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    return _agruparMiles(texto);
  }

  /// Importe monetario con dos decimales.
  static String moneda(String? valor) {
    final numero = double.tryParse(valor ?? '');
    if (numero == null) return valor ?? '—';
    return '\$${_agruparMiles(numero.toStringAsFixed(2))}';
  }

  /// Fecha y hora en zona local, formato corto.
  static String fechaHora(DateTime? fecha) {
    if (fecha == null) return '—';
    final l = fecha.toLocal();
    String dd(int n) => n.toString().padLeft(2, '0');
    return '${dd(l.day)}/${dd(l.month)}/${l.year} ${dd(l.hour)}:${dd(l.minute)}';
  }

  /// Etiqueta legible para los tipos del ENUM movimiento_tipo del backend.
  static String tipoMovimiento(String tipo) {
    const etiquetas = {
      'entrada': 'Entrada',
      'salida': 'Salida',
      'ajuste_positivo': 'Ajuste +',
      'ajuste_negativo': 'Ajuste −',
      'transferencia_salida': 'Transferencia salida',
      'transferencia_entrada': 'Transferencia entrada',
    };
    return etiquetas[tipo] ?? tipo;
  }

  /// Etiqueta legible para los motivos de ajuste que acepta el backend.
  static String motivoAjuste(String motivo) {
    const etiquetas = {
      'merma': 'Merma',
      'conteo_fisico': 'Conteo físico',
      'otro': 'Otro',
    };
    return etiquetas[motivo] ?? motivo;
  }

  static String _agruparMiles(String numero) {
    final partes = numero.split('.');
    final entera = partes.first;
    final resto = partes.length > 1 ? '.${partes[1]}' : '';

    final buffer = StringBuffer();
    for (var i = 0; i < entera.length; i++) {
      if (i > 0 && (entera.length - i) % 3 == 0 && entera[i - 1] != '-') {
        buffer.write(',');
      }
      buffer.write(entera[i]);
    }
    return '$buffer$resto';
  }
}
