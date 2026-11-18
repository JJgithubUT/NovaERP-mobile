import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';

/// Selector de rango de fechas compartido por los reportes.
///
/// Ofrece atajos (hoy, 7 dias, 30 dias) porque son el 90 % de las consultas
/// desde el telefono, y un rango a medida para el resto.
class FiltroFechas extends StatelessWidget {
  const FiltroFechas({
    super.key,
    required this.desde,
    required this.hasta,
    required this.onCambio,
  });

  final DateTime? desde;
  final DateTime? hasta;
  final void Function(DateTime? desde, DateTime? hasta) onCambio;

  bool get _hayFiltro => desde != null || hasta != null;

  String get _etiqueta {
    if (!_hayFiltro) return 'Todo el periodo';
    String dd(DateTime f) =>
        '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}';
    if (desde != null && hasta != null) return '${dd(desde!)} – ${dd(hasta!)}';
    if (desde != null) return 'Desde ${dd(desde!)}';
    return 'Hasta ${dd(hasta!)}';
  }

  /// Primer dia de una ventana de [dias] dias que termina hoy ([hoy] incluido).
  ///
  /// Aritmetica de CALENDARIO, no de duracion: restar `Duration(days: n)` resta
  /// n x 24 h exactas y, si la ventana cruza el cambio de hora de primavera, cae
  /// a las 23:00 del dia anterior (un dia de mas en el reporte y en la etiqueta).
  @visibleForTesting
  static DateTime inicioUltimosDias(DateTime hoy, int dias) =>
      DateTime(hoy.year, hoy.month, hoy.day - (dias - 1));

  void _ultimosDias(int dias) {
    final hoy = DateTime.now();
    onCambio(inicioUltimosDias(hoy, dias), hoy);
  }

  Future<void> _rangoAMedida(BuildContext context) async {
    final hoy = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(hoy.year - 5),
      lastDate: hoy,
      initialDateRange: desde != null && hasta != null
          ? DateTimeRange(start: desde!, end: hasta!)
          : null,
      helpText: 'Periodo del reporte',
      saveText: 'Aplicar',
    );
    if (rango != null) onCambio(rango.start, rango.end);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _Pastilla(
            etiqueta: 'Todo',
            activa: !_hayFiltro,
            onTap: () => onCambio(null, null),
          ),
          _Pastilla(etiqueta: 'Hoy', activa: false, onTap: () => _ultimosDias(1)),
          _Pastilla(
            etiqueta: '7 días',
            activa: false,
            onTap: () => _ultimosDias(7),
          ),
          _Pastilla(
            etiqueta: '30 días',
            activa: false,
            onTap: () => _ultimosDias(30),
          ),
          _Pastilla(
            etiqueta: _hayFiltro ? _etiqueta : 'Personalizado',
            activa: _hayFiltro,
            icono: Icons.date_range,
            onTap: () => _rangoAMedida(context),
          ),
        ],
      ),
    );
  }
}

class _Pastilla extends StatelessWidget {
  const _Pastilla({
    required this.etiqueta,
    required this.activa,
    required this.onTap,
    this.icono,
  });

  final String etiqueta;
  final bool activa;
  final VoidCallback onTap;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        avatar: icono == null
            ? null
            : Icon(
                icono,
                size: 15,
                color: activa ? Colors.white : AppColors.grey,
              ),
        label: Text(etiqueta),
        selected: activa,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          fontSize: 12.5,
          color: activa ? Colors.white : AppColors.black,
          fontWeight: activa ? FontWeight.w600 : FontWeight.normal,
        ),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.white,
        showCheckmark: false,
        side: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
      ),
    );
  }
}
