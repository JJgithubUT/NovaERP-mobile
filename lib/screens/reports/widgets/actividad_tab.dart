import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/descarga.dart';
import '../../../core/utils/formato.dart';
import '../../../core/widgets/lista_paginada.dart';
import '../../../models/reportes.dart';
import '../../../services/reportes_service.dart';
import 'filtro_fechas.dart';

/// HU23 - Reporte de actividad de usuarios.
///
/// Por usuario del tenant: ultimo acceso, numero de sesiones, numero de acciones
/// CUD (altas, cambios y bajas) y estado actual. Filtrable por rango de fechas y
/// por departamento y puesto, y exportable a CSV y PDF con los mismos filtros.
///
/// El rango de fechas acota las sesiones y las acciones contadas, NO la lista de
/// usuarios ni el ultimo acceso. El backend limita el reporte al tenant del
/// solicitante.
///
/// Contrato que usa ReportesScreen: la clase `ActividadTab` (sin parametros).
/// [ActividadTabState.recargar] queda publico para refrescar el reporte desde
/// fuera.
///
/// La pestana conserva su estado (filtros, catalogo y lista cargada) al cambiar
/// de pestana; sin eso, volver desde "Alertas" borraria los filtros y repetiria
/// hasta 10 peticiones del catalogo.
class ActividadTab extends StatefulWidget {
  const ActividadTab({super.key});

  @override
  State<ActividadTab> createState() => ActividadTabState();
}

class ActividadTabState extends State<ActividadTab>
    with AutomaticKeepAliveClientMixin<ActividadTab> {
  static const _errorGeneracion =
      'No fue posible generar el reporte de actividad.';

  final _servicio = ReportesService();
  final _listaKey = GlobalKey<ListaPaginadaState<ActividadUsuario>>();

  DateTime? _desde;
  DateTime? _hasta;
  String? _departamento;
  String? _puesto;

  /// Valores que existen en el tenant, para las listas del panel de filtros. Es
  /// un notificador para que la hoja de filtros, que vive en su propia ruta, se
  /// entere cuando el catalogo llega (o falla) con la hoja ya abierta.
  final _catalogo = ValueNotifier<_Catalogo>(const _Catalogo());
  bool _leyendoCatalogo = false;

  bool _exportando = false;

  @override
  bool get wantKeepAlive => true;

  int get _filtrosAdscripcion =>
      [_departamento, _puesto].where((f) => f != null).length;

  bool get _hayFiltros =>
      _filtrosAdscripcion > 0 || _desde != null || _hasta != null;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  @override
  void dispose() {
    _catalogo.dispose();
    super.dispose();
  }

  /// Lee los departamentos y puestos que existen en el tenant.
  ///
  /// Con [enSegundoPlano] (el catalogo ya esta listo) no pasa por "cargando": los
  /// valores visibles se quedan hasta que llegan los nuevos y, si la lectura
  /// falla, se conserva el catalogo anterior.
  Future<void> _cargarCatalogo({bool enSegundoPlano = false}) async {
    // Tambien se llama desde rutas que sobreviven a la pestana (el "Reintentar"
    // de la hoja de filtros): si ya no esta montada no hay nada que actualizar y
    // el notificador ya se descarto.
    if (!mounted || _leyendoCatalogo) return;
    _leyendoCatalogo = true;
    if (!enSegundoPlano) {
      _catalogo.value = const _Catalogo(estado: _EstadoCatalogo.cargando);
    }
    try {
      final c = await _servicio.catalogoAdscripcion();
      if (!mounted) return;
      _catalogo.value = _Catalogo(
        estado: _EstadoCatalogo.listo,
        departamentos: c.departamentos,
        puestos: c.puestos,
      );
    } catch (_) {
      // Sin catalogo el reporte sigue funcionando: la hoja avisa que no se
      // pudieron cargar los valores y ofrece reintentar. Se atrapa todo (no solo
      // ApiException) para no dejar el aviso de "cargando" para siempre.
      if (mounted && !enSegundoPlano) {
        _catalogo.value = const _Catalogo(estado: _EstadoCatalogo.error);
      }
    } finally {
      _leyendoCatalogo = false;
    }
  }

  /// Vuelve a pedir la primera pagina con los filtros vigentes.
  void recargar() => _listaKey.currentState?.recargar();

  void _cambiarFechas(DateTime? desde, DateTime? hasta) {
    // El selector de rango es una ruta aparte: puede cerrarse despues de que la
    // pestana se haya desmontado (por ejemplo, al cerrar sesion).
    if (!mounted) return;
    setState(() {
      _desde = desde;
      _hasta = hasta;
    });
    recargar();
  }

  Future<void> _abrirFiltros() async {
    // Si la lectura anterior fallo, abrir el panel la intenta de nuevo. Si ya
    // esta lista, se relee en segundo plano para ofrecer los departamentos y
    // puestos que aparecieron despues del arranque (la pestana vive toda la
    // sesion): la hoja se actualiza sola al llegar. Si hay una lectura en curso,
    // no se repite.
    _cargarCatalogo(
      enSegundoPlano: _catalogo.value.estado == _EstadoCatalogo.listo,
    );

    final resultado = await showModalBottomSheet<_FiltrosAdscripcion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ValueListenableBuilder<_Catalogo>(
        valueListenable: _catalogo,
        builder: (_, catalogo, _) => _HojaFiltros(
          catalogo: catalogo,
          onReintentar: _cargarCatalogo,
          inicial: _FiltrosAdscripcion(_departamento, _puesto),
        ),
      ),
    );
    if (resultado == null || !mounted) return;
    setState(() {
      _departamento = resultado.departamento;
      _puesto = resultado.puesto;
    });
    recargar();
  }

  void _limpiarFiltros() {
    setState(() {
      _desde = null;
      _hasta = null;
      _departamento = null;
      _puesto = null;
    });
    recargar();
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
      final archivo = await _servicio.exportarActividad(
        formato: formato,
        desde: _desde,
        hasta: _hasta,
        departamento: _departamento,
        puesto: _puesto,
      );
      await guardarArchivo(archivo);
      aviso('Reporte exportado (${formato.toUpperCase()}).', exito: true);
    } on ApiException catch (e) {
      // 403 trae el detalle del permiso. El 400 (p. ej. el tope de 20000 filas:
      // "acote el rango de fechas u otros filtros") conserva el texto del
      // criterio y le suma el detalle del backend, que es lo unico que le dice
      // al usuario como resolverlo. El resto, solo el texto del criterio.
      if (e.esPermisoDenegado) {
        aviso(e.mensaje);
      } else if (e.statusCode == 400) {
        aviso('$_errorGeneracion ${e.mensaje}', largo: true);
      } else {
        aviso(_errorGeneracion);
      }
    } catch (_) {
      aviso(_errorGeneracion);
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // obligatorio con AutomaticKeepAliveClientMixin
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
                  isLabelVisible: _filtrosAdscripcion > 0,
                  label: Text('$_filtrosAdscripcion'),
                  child: const Icon(Icons.filter_list, size: 20),
                ),
                label: const Text('Filtros'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: _filtrosAdscripcion > 0
                        ? AppColors.primary
                        : AppColors.grey.withValues(alpha: 0.4),
                  ),
                ),
              ),
              if (_hayFiltros)
                TextButton(
                  onPressed: _limpiarFiltros,
                  child: const Text('Limpiar'),
                ),
              const Spacer(),
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
        FiltroFechas(desde: _desde, hasta: _hasta, onCambio: _cambiarFechas),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'El periodo acota las sesiones y acciones, no el último acceso.',
              style: TextStyle(fontSize: 11.5, color: AppColors.grey),
            ),
          ),
        ),
        Expanded(
          child: ListaPaginada<ActividadUsuario>(
            key: _listaKey,
            cargar: (pagina) => _servicio.actividad(
              pagina: pagina,
              desde: _desde,
              hasta: _hasta,
              departamento: _departamento,
              puesto: _puesto,
            ),
            mensajeError: _errorGeneracion,
            mensajeVacio: _hayFiltros
                ? 'No hay usuarios para los criterios seleccionados.'
                : 'Aún no hay usuarios en el reporte.',
            iconoVacio: Icons.insights_outlined,
            itemBuilder: (contexto, fila) => _FilaActividad(fila: fila),
          ),
        ),
      ],
    );
  }
}

class _FiltrosAdscripcion {
  const _FiltrosAdscripcion(this.departamento, this.puesto);

  final String? departamento;
  final String? puesto;
}

/// En que va la lectura de los departamentos y puestos del tenant.
enum _EstadoCatalogo { cargando, listo, error }

/// Departamentos y puestos que existen en el tenant, y el estado de su lectura.
class _Catalogo {
  const _Catalogo({
    this.estado = _EstadoCatalogo.cargando,
    this.departamentos = const [],
    this.puestos = const [],
  });

  final _EstadoCatalogo estado;
  final List<String> departamentos;
  final List<String> puestos;
}

/// Hoja inferior con los filtros de departamento y puesto.
class _HojaFiltros extends StatefulWidget {
  const _HojaFiltros({
    required this.catalogo,
    required this.onReintentar,
    required this.inicial,
  });

  final _Catalogo catalogo;
  final VoidCallback onReintentar;
  final _FiltrosAdscripcion inicial;

  @override
  State<_HojaFiltros> createState() => _HojaFiltrosState();
}

class _HojaFiltrosState extends State<_HojaFiltros> {
  late String? _departamento = widget.inicial.departamento;
  late String? _puesto = widget.inicial.puesto;

  /// La lista debe contener el valor elegido; si el catalogo no lo trae (por
  /// ejemplo por haber cambiado), se agrega para que el desplegable no falle.
  List<String> _con(List<String> base, String? elegido) =>
      elegido == null || base.contains(elegido) ? base : [...base, elegido];

  @override
  Widget build(BuildContext context) {
    final catalogo = widget.catalogo;
    final departamentos = _con(catalogo.departamentos, _departamento);
    final puestos = _con(catalogo.puestos, _puesto);

    return Container(
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
              if (catalogo.estado == _EstadoCatalogo.cargando)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cargando departamentos y puestos…',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (catalogo.estado == _EstadoCatalogo.error)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'No se pudieron cargar los departamentos y puestos.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onReintentar,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              else if (departamentos.isEmpty && puestos.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Sin datos de departamento ni puesto para filtrar.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.warning),
                  ),
                ),
              DropdownButtonFormField<String?>(
                initialValue: _departamento,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Departamento',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  for (final d in departamentos)
                    DropdownMenuItem<String?>(
                      value: d,
                      child: Text(d, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _departamento = v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String?>(
                initialValue: _puesto,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Puesto',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todos'),
                  ),
                  for (final p in puestos)
                    DropdownMenuItem<String?>(
                      value: p,
                      child: Text(p, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _puesto = v),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(const _FiltrosAdscripcion(null, null)),
                      child: const Text('Quitar filtros'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(_FiltrosAdscripcion(_departamento, _puesto)),
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
    );
  }
}

class _FilaActividad extends StatelessWidget {
  const _FilaActividad({required this.fila});

  final ActividadUsuario fila;

  /// Etiqueta y color del estado. Se muestra SIEMPRE (el criterio pide el estado
  /// actual); un valor desconocido se pinta tal cual llega.
  static (String, Color) _estado(String estado) =>
      switch (estado.toLowerCase()) {
        'activo' => ('Activo', AppColors.success),
        'pendiente' => ('Pendiente', AppColors.warning),
        'pendiente_verificacion' => (
          'Pendiente de verificación',
          AppColors.warning,
        ),
        'suspendido' => ('Suspendido', AppColors.primaryLight),
        _ => (estado, AppColors.grey),
      };

  @override
  Widget build(BuildContext context) {
    final (etiquetaEstado, colorEstado) = _estado(fila.estado);

    // Un puesto o departamento vacio no merece una linea con separadores sueltos.
    final adscripcion = [
      fila.puesto,
      fila.departamento,
    ].where((v) => v != null && v.isNotEmpty).join(' · ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: colorEstado.withValues(alpha: 0.12),
        child: Text(
          _iniciales(fila.nombreCompleto),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colorEstado,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              fila.nombreCompleto,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorEstado.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              etiquetaEstado,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: colorEstado,
              ),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (adscripcion.isNotEmpty)
              Text(
                adscripcion,
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            Text(
              fila.sinAcceso
                  ? 'Nunca ha ingresado'
                  : 'Último acceso ${Formato.fechaHora(fila.ultimoAcceso)}',
              style: TextStyle(
                fontSize: 12,
                color: fila.sinAcceso ? AppColors.warning : AppColors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _Metrica(
                  icono: Icons.devices_outlined,
                  valor: fila.numSesiones,
                  etiqueta: 'sesiones',
                ),
                const SizedBox(width: 14),
                _Metrica(
                  icono: Icons.edit_note_outlined,
                  valor: fila.numAccionesCud,
                  etiqueta: 'acciones',
                ),
              ],
            ),
          ],
        ),
      ),
      isThreeLine: true,
    );
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({
    required this.icono,
    required this.valor,
    required this.etiqueta,
  });

  final IconData icono;
  final int valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: AppColors.grey),
        const SizedBox(width: 4),
        Text(
          '$valor',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          etiqueta,
          style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
        ),
      ],
    );
  }
}
