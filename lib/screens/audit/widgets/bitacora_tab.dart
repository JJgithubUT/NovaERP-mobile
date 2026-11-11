import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/permisos.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/descarga.dart';
import '../../../core/utils/formato.dart';
import '../../../core/widgets/lista_paginada.dart';
import '../../../models/auditoria.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auditoria_service.dart';
import '../detalle_evento.dart';

/// HU21 - Consulta de bitacora de auditoria del tenant.
///
/// Vista estrictamente de solo lectura (la bitacora es append-only), de lo mas
/// reciente a lo mas antiguo, con filtros por usuario, fecha, tipo de operacion y
/// entidad afectada. Exportable a CSV o PDF con los mismos filtros, solo con el
/// permiso `core:bitacora:exportar`. Al tocar un evento se abre su detalle (HU20).
///
/// El filtro de tenant lo aplica el backend: no existe forma de ver otro.
class BitacoraTab extends StatefulWidget {
  const BitacoraTab({super.key});

  @override
  State<BitacoraTab> createState() => BitacoraTabState();
}

class BitacoraTabState extends State<BitacoraTab> {
  static const _errorConsulta =
      'No fue posible consultar la bitácora de auditoría.';

  static const _operaciones = {
    'LOGIN': 'Ingresos',
    'LOGIN_FAILED': 'Fallos de acceso',
    'INSERT': 'Altas',
    'UPDATE': 'Cambios',
    'DELETE': 'Bajas',
    'EXPORT': 'Exportaciones',
  };

  /// Entidades mas comunes, como sugerencia del filtro (se acepta cualquiera).
  static const _entidadesComunes = [
    'usuario',
    'rol',
    'rol_permiso',
    'usuario_rol',
    'sesion',
    'notificacion',
    'tenant_modulo',
    'log_auditoria',
  ];

  final _servicio = AuditoriaService();
  final _listaKey = GlobalKey<ListaPaginadaState<EventoAuditoria>>();

  /// La bitacora solo trae usuario_id; los nombres se resuelven aparte.
  Map<String, String> _nombres = const {};

  String? _usuarioId;
  String? _operacion;
  String? _entidad;
  DateTime? _desde;
  DateTime? _hasta;
  bool _exportando = false;

  int get _filtrosAvanzados => [
    _usuarioId,
    _entidad,
    _desde,
    _hasta,
  ].where((f) => f != null).length;

  @override
  void initState() {
    super.initState();
    _cargarNombres();
  }

  Future<void> _cargarNombres() async {
    final nombres = await _servicio.nombresDeUsuario();
    if (mounted) setState(() => _nombres = nombres);
  }

  /// Vuelve a pedir la primera pagina con los filtros vigentes.
  void recargar() => _listaKey.currentState?.recargar();

  String _nombreDe(String? usuarioId) {
    if (usuarioId == null) return 'Sistema';
    return _nombres[usuarioId] ?? 'Usuario ${usuarioId.substring(0, 6)}…';
  }

  void _elegirOperacion(String? operacion) {
    if (operacion == _operacion) return;
    setState(() => _operacion = operacion);
    recargar();
  }

  Future<void> _abrirFiltros() async {
    final resultado = await showModalBottomSheet<_Filtros>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HojaFiltros(
        inicial: _Filtros(
          usuarioId: _usuarioId,
          entidad: _entidad,
          desde: _desde,
          hasta: _hasta,
        ),
        nombres: _nombres,
        entidades: _entidadesComunes,
      ),
    );
    if (resultado == null || !mounted) return;
    setState(() {
      _usuarioId = resultado.usuarioId;
      _entidad = resultado.entidad;
      _desde = resultado.desde;
      _hasta = resultado.hasta;
    });
    recargar();
  }

  void _limpiarFiltros() {
    setState(() {
      _usuarioId = null;
      _operacion = null;
      _entidad = null;
      _desde = null;
      _hasta = null;
    });
    recargar();
  }

  Future<void> _exportar(String formato) async {
    setState(() => _exportando = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final archivo = await _servicio.exportarBitacora(
        formato: formato,
        usuarioId: _usuarioId,
        operacion: _operacion,
        entidad: _entidad,
        desde: _desde,
        hasta: _hasta,
      );
      await guardarArchivo(archivo);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            'Bitácora exportada (${formato.toUpperCase()}).',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            e.esPermisoDenegado || e.esReglaDeNegocio
                ? e.mensaje
                : 'No fue posible exportar la bitácora de auditoría.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            'No fue posible exportar la bitácora de auditoría.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hayFiltros = _filtrosAvanzados > 0 || _operacion != null;

    // Los filtros viven FUERA de la lista para no reconstruirlos en cada consulta.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: _abrirFiltros,
                icon: Badge(
                  isLabelVisible: _filtrosAvanzados > 0,
                  label: Text('$_filtrosAvanzados'),
                  child: const Icon(Icons.filter_list, size: 20),
                ),
                label: const Text('Filtros'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: _filtrosAvanzados > 0
                        ? AppColors.primary
                        : AppColors.grey.withValues(alpha: 0.4),
                  ),
                ),
              ),
              if (hayFiltros)
                TextButton(
                  onPressed: _limpiarFiltros,
                  child: const Text('Limpiar'),
                ),
              const Spacer(),
              if (auth.puede(Permisos.bitacoraExportar))
                _exportando
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : PopupMenuButton<String>(
                        tooltip: 'Exportar',
                        onSelected: _exportar,
                        icon: const Icon(
                          Icons.file_download_outlined,
                          color: AppColors.primary,
                        ),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'csv',
                            child: Text('Exportar a CSV'),
                          ),
                          PopupMenuItem(
                            value: 'pdf',
                            child: Text('Exportar a PDF'),
                          ),
                        ],
                      ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _Pastilla(
                etiqueta: 'Todos',
                activa: _operacion == null,
                onTap: () => _elegirOperacion(null),
              ),
              for (final e in _operaciones.entries)
                _Pastilla(
                  etiqueta: e.value,
                  activa: _operacion == e.key,
                  onTap: () => _elegirOperacion(e.key),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListaPaginada<EventoAuditoria>(
            key: _listaKey,
            cargar: (pagina) => _servicio.bitacora(
              pagina: pagina,
              usuarioId: _usuarioId,
              operacion: _operacion,
              entidad: _entidad,
              desde: _desde,
              hasta: _hasta,
            ),
            mensajeError: _errorConsulta,
            mensajeVacio: hayFiltros
                ? 'No se encontraron eventos para los criterios seleccionados.'
                : 'Aún no hay eventos registrados.',
            iconoVacio: Icons.fact_check_outlined,
            itemBuilder: (contexto, evento) => _FilaEvento(
              evento: evento,
              nombre: _nombreDe(evento.usuarioId),
              onAbrir: () => abrirDetalleEvento(
                contexto,
                evento,
                nombreUsuario: evento.usuarioId == null
                    ? null
                    : _nombres[evento.usuarioId],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Filtros {
  const _Filtros({this.usuarioId, this.entidad, this.desde, this.hasta});

  final String? usuarioId;
  final String? entidad;
  final DateTime? desde;
  final DateTime? hasta;
}

/// Hoja inferior con los filtros avanzados: usuario, entidad y rango de fechas.
class _HojaFiltros extends StatefulWidget {
  const _HojaFiltros({
    required this.inicial,
    required this.nombres,
    required this.entidades,
  });

  final _Filtros inicial;
  final Map<String, String> nombres;
  final List<String> entidades;

  @override
  State<_HojaFiltros> createState() => _HojaFiltrosState();
}

class _HojaFiltrosState extends State<_HojaFiltros> {
  late String? _usuarioId = widget.inicial.usuarioId;
  late DateTime? _desde = widget.inicial.desde;
  late DateTime? _hasta = widget.inicial.hasta;
  late final _entidad = TextEditingController(text: widget.inicial.entidad);

  @override
  void dispose() {
    _entidad.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha({required bool esDesde}) async {
    final actual = esDesde ? _desde : _hasta;
    final elegida = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (elegida == null) return;
    setState(() => esDesde ? _desde = elegida : _hasta = elegida);
  }

  String _fecha(DateTime? f) {
    if (f == null) return 'Cualquiera';
    String dd(int n) => n.toString().padLeft(2, '0');
    return '${dd(f.day)}/${dd(f.month)}/${f.year}';
  }

  @override
  Widget build(BuildContext context) {
    final rangoInvalido =
        _desde != null && _hasta != null && _desde!.isAfter(_hasta!);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: _usuarioId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    for (final e in widget.nombres.entries)
                      DropdownMenuItem<String?>(
                        value: e.key,
                        child: Text(e.value, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _usuarioId = v),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _entidad,
                  // Reconstruye las sugerencias resaltadas al escribir.
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Entidad afectada',
                    hintText: 'usuario, rol, sesion…',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 0,
                  children: [
                    for (final e in widget.entidades)
                      ActionChip(
                        label: Text(e, style: const TextStyle(fontSize: 11.5)),
                        backgroundColor: _entidad.text.trim() == e
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : null,
                        onPressed: () => setState(() => _entidad.text = e),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _elegirFecha(esDesde: true),
                        child: Text('Desde: ${_fecha(_desde)}'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _elegirFecha(esDesde: false),
                        child: Text('Hasta: ${_fecha(_hasta)}'),
                      ),
                    ),
                  ],
                ),
                if (rangoInvalido)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'La fecha inicial no puede ser posterior a la final.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.primary),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(
                          const _Filtros(),
                        ),
                        child: const Text('Quitar filtros'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: rangoInvalido
                            ? null
                            : () => Navigator.of(context).pop(
                                _Filtros(
                                  usuarioId: _usuarioId,
                                  entidad: _entidad.text.trim().isEmpty
                                      ? null
                                      : _entidad.text.trim(),
                                  desde: _desde,
                                  hasta: _hasta,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pastilla extends StatelessWidget {
  const _Pastilla({
    required this.etiqueta,
    required this.activa,
    required this.onTap,
  });

  final String etiqueta;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: ChoiceChip(
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

class _FilaEvento extends StatelessWidget {
  const _FilaEvento({
    required this.evento,
    required this.nombre,
    required this.onAbrir,
  });

  final EventoAuditoria evento;
  final String nombre;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final (icono, color, etiqueta) = switch (evento.operacion.toUpperCase()) {
      'INSERT' => (Icons.add_circle_outline, AppColors.success, 'Alta'),
      'UPDATE' => (Icons.edit_outlined, AppColors.primary, 'Cambio'),
      'DELETE' => (Icons.delete_outline, AppColors.primaryLight, 'Baja'),
      'LOGIN' => (Icons.login, AppColors.grey, 'Ingreso'),
      'LOGIN_FAILED' => (Icons.lock_outline, AppColors.warning, 'Fallo de acceso'),
      'EXPORT' => (Icons.file_download_outlined, AppColors.primary, 'Exportación'),
      _ => (Icons.circle_outlined, AppColors.grey, evento.operacion),
    };

    return ListTile(
      onTap: onAbrir,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 19,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icono, size: 19, color: color),
      ),
      title: Text(
        '$etiqueta · ${evento.entidad}',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
      ),
      subtitle: Text(
        '$nombre\n${Formato.fechaHora(evento.ocurridoEn)}'
        '${evento.ipOrigen == null ? '' : ' · ${evento.ipOrigen}'}',
        style: const TextStyle(fontSize: 12, color: AppColors.grey, height: 1.4),
      ),
      isThreeLine: true,
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.grey,
        size: 20,
      ),
    );
  }
}
