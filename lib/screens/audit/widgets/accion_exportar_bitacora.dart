import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/permisos.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/descarga.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auditoria_service.dart';

/// HU24 - Exportacion de la bitacora de auditoria. Boton de la cabecera de la
/// bitacora (screens/audit/widgets/bitacora_tab.dart), junto a los filtros.
///
/// Menu con "Exportar a CSV" y "Exportar a PDF". Exporta con los MISMOS filtros
/// que la lista (los recibe como parametros) y entrega el archivo con
/// `guardarArchivo`. El menu muestra arriba, sin accion, un resumen de los
/// filtros que se aplicaran. Solo se muestra con el permiso
/// `core:bitacora:exportar`.
///
/// El backend agrega al archivo los metadatos (tenant, quien lo genero, fecha y
/// hora, filtros aplicados) y registra cada exportacion como un evento EXPORT en
/// la propia bitacora; por eso la app no agrega nada al archivo.
///
/// Error: "No fue posible exportar la bitácora de auditoría." Si el backend
/// rechaza la exportacion por exceder el tope de filas (400), se le suma su
/// detalle ("acote el rango de fechas u otros filtros").
///
/// Contrato que usa BitacoraTab: el nombre de la clase y sus parametros. El
/// ultimo ([onExportada]) es opcional.
class AccionExportarBitacora extends StatefulWidget {
  const AccionExportarBitacora({
    super.key,
    this.usuarioId,
    this.operacion,
    this.entidad,
    this.desde,
    this.hasta,
    this.onExportada,
  });

  /// Filtros vigentes de la bitacora.
  final String? usuarioId;
  final String? operacion;
  final String? entidad;
  final DateTime? desde;
  final DateTime? hasta;

  /// Se llama tras una exportacion correcta: el backend acaba de registrar el
  /// evento EXPORT y la bitacora debe volver a pedirse para mostrarlo.
  final VoidCallback? onExportada;

  @override
  State<AccionExportarBitacora> createState() => _AccionExportarBitacoraState();
}

class _AccionExportarBitacoraState extends State<AccionExportarBitacora> {
  static const _errorGeneral =
      'No fue posible exportar la bitácora de auditoría.';

  final _servicio = AuditoriaService();
  bool _exportando = false;

  /// Lo que se va a exportar, para que quien exporta no lo haga a ciegas.
  String get _resumenFiltros {
    String f(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final partes = [
      if (widget.operacion != null) 'Operación: ${widget.operacion}',
      if (widget.usuarioId != null) 'Usuario filtrado',
      if (widget.entidad != null) 'Entidad: ${widget.entidad}',
      if (widget.desde != null) 'Desde: ${f(widget.desde!)}',
      if (widget.hasta != null) 'Hasta: ${f(widget.hasta!)}',
    ];
    return partes.isEmpty
        ? 'Sin filtros: toda la bitácora'
        : partes.join(' · ');
  }

  Future<void> _exportar(String formato) async {
    if (_exportando) return;
    setState(() => _exportando = true);
    final messenger = ScaffoldMessenger.of(context);
    void aviso(String texto, {bool exito = false, bool largo = false}) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: exito ? AppColors.success : AppColors.primary,
          duration: Duration(seconds: largo ? 8 : 4),
          content: Text(texto, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    try {
      final archivo = await _servicio.exportarBitacora(
        formato: formato,
        usuarioId: widget.usuarioId,
        operacion: widget.operacion,
        entidad: widget.entidad,
        desde: widget.desde,
        hasta: widget.hasta,
      );
      await guardarArchivo(archivo);
      aviso('Bitácora exportada (${formato.toUpperCase()}).', exito: true);
      // Va despues del aviso (sale primero el mensaje) y de guardarArchivo (en
      // movil espera a la hoja de compartir): el evento EXPORT ya esta en la
      // base, asi que la lista lo trae en primer lugar.
      if (mounted) widget.onExportada?.call();
    } on ApiException catch (e) {
      // 403 (sin permiso) y 422 traen un mensaje especifico. El 400 (p. ej. el
      // tope de 20000 filas: "acote el rango de fechas u otros filtros")
      // conserva el texto fijado por el criterio y le suma el detalle del
      // backend, que es lo unico que le dice al usuario como resolverlo. Los
      // demas (red, 5xx), solo el texto fijado por el criterio.
      if (e.esPermisoDenegado || e.esReglaDeNegocio) {
        aviso(e.mensaje);
      } else if (e.statusCode == 400) {
        aviso('$_errorGeneral ${e.mensaje}', largo: true);
      } else {
        aviso(_errorGeneral);
      }
    } catch (_) {
      aviso(_errorGeneral);
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.puede(Permisos.bitacoraExportar)) return const SizedBox.shrink();

    if (_exportando) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Exportar',
      onSelected: _exportar,
      icon: const Icon(Icons.file_download_outlined, color: AppColors.primary),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            _resumenFiltros,
            style: const TextStyle(fontSize: 12, color: AppColors.grey),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'csv',
          child: Text('Exportar a CSV'),
        ),
        const PopupMenuItem<String>(
          value: 'pdf',
          child: Text('Exportar a PDF'),
        ),
      ],
    );
  }
}
