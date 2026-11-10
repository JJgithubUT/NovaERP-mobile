import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/widgets/lista_paginada.dart';
import '../../../models/personal.dart';
import '../../../services/personal_service.dart';
import '../detalle_usuario.dart';

/// Directorio de usuarios del tenant, con busqueda y filtro por estado.
class UsuariosTab extends StatefulWidget {
  const UsuariosTab({super.key});

  @override
  State<UsuariosTab> createState() => UsuariosTabState();
}

class UsuariosTabState extends State<UsuariosTab>
    with WidgetsBindingObserver {
  /// Espera tras la ultima tecla antes de consultar. Sin esto cada letra seria
  /// una peticion; con esto el filtro se aplica solo cuando el usuario se
  /// detiene, sin tener que pulsar Enter.
  static const _esperaBusqueda = Duration(milliseconds: 350);

  /// Al volver a la app no se refresca si la lista se cargo hace menos que esto:
  /// en web el "volver" se dispara con cualquier cambio de foco.
  static const _minimoEntreRefrescos = Duration(seconds: 20);

  final _servicio = PersonalService();
  DateTime _ultimaCarga = DateTime.now();
  final _listaKey = GlobalKey<ListaPaginadaState<UsuarioDirectorio>>();
  final _busquedaController = TextEditingController();
  Timer? _temporizador;

  String _busqueda = '';
  String? _estado;

  static const _estados = {
    'activo': 'Activos',
    'pendiente': 'Pendientes',
    'suspendido': 'Suspendidos',
  };

  bool get _hayFiltros => _busqueda.isNotEmpty || _estado != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _temporizador?.cancel();
    _busquedaController.dispose();
    super.dispose();
  }

  /// Al volver a la app (o a la pestana del navegador) se actualiza el
  /// directorio en segundo plano: pudo cambiar desde otro dispositivo o desde
  /// la web. Es silencioso (la lista no se vacia) y a lo mas una vez cada
  /// [_minimoEntreRefrescos].
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado != AppLifecycleState.resumed) return;
    final ahora = DateTime.now();
    if (ahora.difference(_ultimaCarga) < _minimoEntreRefrescos) return;
    _ultimaCarga = ahora;
    _listaKey.currentState?.actualizar();
  }

  /// Vuelve a pedir la primera pagina con la busqueda y el filtro vigentes.
  /// La llama StaffScreen tras un alta y la ficha tras editar o suspender.
  void recargar() {
    _ultimaCarga = DateTime.now();
    _listaKey.currentState?.recargar();
  }

  void _alEscribir(String valor) {
    // Refresca el boton de limpiar.
    setState(() {});
    _temporizador?.cancel();
    _temporizador = Timer(_esperaBusqueda, () => _aplicarBusqueda(valor));
  }

  void _aplicarBusqueda(String valor) {
    final limpio = valor.trim();
    if (limpio == _busqueda) return;
    setState(() => _busqueda = limpio);
    recargar();
  }

  void _limpiarBusqueda() {
    _temporizador?.cancel();
    _busquedaController.clear();
    _aplicarBusqueda('');
  }

  void _elegirEstado(String? estado) {
    if (estado == _estado) return;
    setState(() => _estado = estado);
    recargar();
  }

  @override
  Widget build(BuildContext context) {
    // El buscador y los filtros viven FUERA de la lista: si estuvieran dentro,
    // cada busqueda reconstruiria el campo de texto y perderia el foco.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _busquedaController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, correo o puesto',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busquedaController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      icon: const Icon(Icons.close),
                      onPressed: _limpiarBusqueda,
                    ),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.grey.withValues(alpha: 0.3),
                ),
              ),
            ),
            onChanged: _alEscribir,
            onSubmitted: (valor) {
              _temporizador?.cancel();
              _aplicarBusqueda(valor);
            },
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
                activa: _estado == null,
                onTap: () => _elegirEstado(null),
              ),
              for (final e in _estados.entries)
                _Pastilla(
                  etiqueta: e.value,
                  activa: _estado == e.key,
                  onTap: () => _elegirEstado(e.key),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListaPaginada<UsuarioDirectorio>(
            key: _listaKey,
            cargar: (pagina) => _servicio.usuarios(
              pagina: pagina,
              busqueda: _busqueda.isEmpty ? null : _busqueda,
              estado: _estado,
            ),
            mensajeVacio: _hayFiltros
                ? 'No se encontraron usuarios para los criterios seleccionados.'
                : 'Aún no hay usuarios registrados.',
            iconoVacio: Icons.person_search_outlined,
            itemBuilder: (contexto, usuario) => _FilaUsuario(
              usuario: usuario,
              onAbrir: () async {
                final cambio = await abrirDetalleUsuario(contexto, usuario);
                if (cambio) recargar();
              },
            ),
          ),
        ),
      ],
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

class _FilaUsuario extends StatelessWidget {
  const _FilaUsuario({required this.usuario, required this.onAbrir});

  final UsuarioDirectorio usuario;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final (color, etiqueta) = switch (usuario.estado.toLowerCase()) {
      'activo' => (AppColors.success, null),
      'suspendido' => (AppColors.primaryLight, 'Suspendido'),
      'pendiente' => (AppColors.warning, 'Pendiente'),
      _ => (AppColors.grey, usuario.estado),
    };

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onAbrir,
      leading: CircleAvatar(
        radius: 21,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Text(
          usuario.iniciales,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              usuario.nombreCompleto,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
              ),
            ),
          ),
          if (etiqueta != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                etiqueta,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          '${usuario.correo}\n'
          '${usuario.roles.isEmpty ? 'Sin roles' : usuario.roles.join(' · ')}'
          '${usuario.ultimoAcceso == null ? '' : ' · ${Formato.fechaHora(usuario.ultimoAcceso)}'}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.grey,
            height: 1.4,
          ),
        ),
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
