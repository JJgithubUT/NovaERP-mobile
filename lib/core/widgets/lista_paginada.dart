import 'package:flutter/material.dart';

import '../../models/paginado.dart';
import '../config/app_colors.dart';
import '../network/api_exception.dart';

/// Lista con scroll infinito, recarga al deslizar y estados de carga, error y
/// vacio resueltos.
///
/// Todos los listados del backend devuelven el mismo sobre paginado, asi que
/// esta pieza se escribe una vez y la reutilizan las pestanas de inventario.
///
/// Para recargar desde fuera (por ejemplo tras registrar un movimiento) se
/// guarda una GlobalKey y se llama a `.currentState?.recargar()`. Para cambiar
/// los filtros basta con darle una Key distinta: el widget se reconstruye
/// desde cero y vuelve a la pagina 1.
class ListaPaginada<T> extends StatefulWidget {
  const ListaPaginada({
    super.key,
    required this.cargar,
    required this.itemBuilder,
    this.mensajeVacio = 'No hay registros',
    this.iconoVacio = Icons.inbox_outlined,
    this.cabecera,
    this.separador = true,
    this.padding,
    this.onDatosCargados,
  });

  /// Carga una pagina concreta (empezando en 1).
  final Future<Paginado<T>> Function(int pagina) cargar;

  final Widget Function(BuildContext contexto, T elemento) itemBuilder;
  final String mensajeVacio;
  final IconData iconoVacio;

  /// Contenido fijo sobre la lista (buscador, filtros, totales).
  final Widget? cabecera;

  final bool separador;
  final EdgeInsets? padding;

  /// Avisa con todo lo acumulado hasta ahora y el total que declara el
  /// servidor. Lo usan los reportes para ir sumando importes conforme se
  /// cargan paginas, sin pedir el conjunto entero de golpe.
  final void Function(List<T> acumulado, int total)? onDatosCargados;

  @override
  State<ListaPaginada<T>> createState() => ListaPaginadaState<T>();
}

class ListaPaginadaState<T> extends State<ListaPaginada<T>> {
  final _scrollController = ScrollController();
  final _elementos = <T>[];

  int _pagina = 0;
  int _total = 0;
  bool _hayMas = true;
  bool _cargando = false;
  ApiException? _error;

  int get total => _total;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_alDesplazar);
    _cargarSiguientePagina();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _alDesplazar() {
    if (!_scrollController.hasClients) return;
    final posicion = _scrollController.position;
    // Se pide la siguiente pagina un poco antes del final para que el usuario
    // no llegue a ver el hueco.
    if (posicion.pixels >= posicion.maxScrollExtent - 300) {
      _cargarSiguientePagina();
    }
  }

  Future<void> _cargarSiguientePagina() async {
    if (_cargando || !_hayMas) return;
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final lote = await widget.cargar(_pagina + 1);
      if (!mounted) return;
      setState(() {
        _pagina = lote.pagina;
        _total = lote.total;
        _hayMas = lote.hayMasPaginas;
        _elementos.addAll(lote.elementos);
        _cargando = false;
      });
      // Tras el setState, para que quien escuche pueda reconstruir su cabecera
      // con el acumulado ya actualizado.
      widget.onDatosCargados?.call(List.unmodifiable(_elementos), _total);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _cargando = false;
      });
    }
  }

  /// Vuelve a empezar desde la pagina 1 conservando la posicion del scroll en
  /// el tope. Se llama tras crear o modificar un registro.
  Future<void> recargar() async {
    setState(() {
      _elementos.clear();
      _pagina = 0;
      _hayMas = true;
      _error = null;
    });
    await _cargarSiguientePagina();
  }

  @override
  Widget build(BuildContext context) {
    // Primer intento fallido: no hay nada que mostrar mas que el error.
    if (_error != null && _elementos.isEmpty) {
      return _EstadoMensaje(
        icono: _error!.esPermisoDenegado
            ? Icons.lock_outline
            : Icons.cloud_off_outlined,
        titulo: _error!.esPermisoDenegado
            ? 'Sin permiso para ver esto'
            : 'No se pudo cargar',
        detalle: _error!.mensaje,
        accion: _error!.esPermisoDenegado ? null : recargar,
      );
    }

    if (_cargando && _elementos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_elementos.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: recargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (widget.cabecera != null) widget.cabecera!,
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: _EstadoMensaje(
                icono: widget.iconoVacio,
                titulo: widget.mensajeVacio,
              ),
            ),
          ],
        ),
      );
    }

    // +1 por la cabecera (si la hay) y +1 por el pie (cargando / error de
    // pagina siguiente / fin de lista).
    final desplazamiento = widget.cabecera != null ? 1 : 0;
    final totalFilas = _elementos.length + desplazamiento + 1;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: recargar,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: widget.padding ?? EdgeInsets.zero,
        itemCount: totalFilas,
        separatorBuilder: (_, indice) {
          if (!widget.separador) return const SizedBox.shrink();
          if (indice < desplazamiento) return const SizedBox.shrink();
          return const Divider(height: 1, indent: 16, endIndent: 16);
        },
        itemBuilder: (contexto, indice) {
          if (widget.cabecera != null && indice == 0) return widget.cabecera!;

          final indiceElemento = indice - desplazamiento;
          if (indiceElemento < _elementos.length) {
            return widget.itemBuilder(contexto, _elementos[indiceElemento]);
          }
          return _Pie(
            cargando: _cargando,
            error: _error,
            hayMas: _hayMas,
            onReintentar: _cargarSiguientePagina,
          );
        },
      ),
    );
  }
}

class _Pie extends StatelessWidget {
  const _Pie({
    required this.cargando,
    required this.error,
    required this.hayMas,
    required this.onReintentar,
  });

  final bool cargando;
  final ApiException? error;
  final bool hayMas;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    // Fallo al pedir una pagina posterior: lo ya cargado sigue siendo util, asi
    // que se ofrece reintentar sin tirar la lista.
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Text(
                error!.mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.grey),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onReintentar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (hayMas) return const SizedBox(height: 24);
    return const SizedBox(height: 32);
  }
}

class _EstadoMensaje extends StatelessWidget {
  const _EstadoMensaje({
    required this.icono,
    required this.titulo,
    this.detalle,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String? detalle;
  final Future<void> Function()? accion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            if (detalle != null) ...[
              const SizedBox(height: 8),
              Text(
                detalle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.grey),
              ),
            ],
            if (accion != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: accion,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
