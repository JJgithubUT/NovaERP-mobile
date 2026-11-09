import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/widgets/lista_paginada.dart';
import '../../../models/personal.dart';
import '../../../services/personal_service.dart';
import 'tarjeta_rol.dart';

/// HU11 - Visualizar roles y permisos asignados.
///
/// Catalogo de roles del tenant (el backend solo devuelve los de la empresa
/// actual), con busqueda por nombre y filtro por estado. Cada rol se pinta con
/// [TarjetaRol]: permisos agrupados por dominio, indicador de inertes y
/// contador de usuarios.
///
/// StaffScreen usa `RolesTab` y [RolesTabState.recargar]; la tarjeta recibe
/// `onCambio: recargar` para que la lista se actualice tras editar, desactivar
/// o reactivar un rol.
class RolesTab extends StatefulWidget {
  const RolesTab({super.key});

  @override
  State<RolesTab> createState() => RolesTabState();
}

class RolesTabState extends State<RolesTab> with WidgetsBindingObserver {
  /// Espera tras la ultima tecla antes de consultar.
  static const _esperaBusqueda = Duration(milliseconds: 350);

  /// Al volver a la app no se refresca si la lista se cargo hace menos que esto.
  static const _minimoEntreRefrescos = Duration(seconds: 20);

  final _servicio = PersonalService();
  final _listaKey = GlobalKey<ListaPaginadaState<Rol>>();
  final _busquedaController = TextEditingController();
  Timer? _temporizador;
  DateTime _ultimaCarga = DateTime.now();

  String _busqueda = '';

  /// null = todos, true = solo activos, false = solo inactivos.
  bool? _activo;

  bool get _hayFiltros => _busqueda.isNotEmpty || _activo != null;

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

  /// Al volver a la app se actualiza en segundo plano (sin vaciar la lista):
  /// los roles pudieron cambiar desde la web.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado != AppLifecycleState.resumed) return;
    final ahora = DateTime.now();
    if (ahora.difference(_ultimaCarga) < _minimoEntreRefrescos) return;
    _ultimaCarga = ahora;
    _listaKey.currentState?.actualizar();
  }

  /// Vuelve a pedir la primera pagina con la busqueda y el filtro vigentes.
  void recargar() {
    _ultimaCarga = DateTime.now();
    _listaKey.currentState?.recargar();
  }

  void _alEscribir(String valor) {
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

  void _elegirEstado(bool? activo) {
    if (activo == _activo) return;
    setState(() => _activo = activo);
    recargar();
  }

  @override
  Widget build(BuildContext context) {
    // El buscador y los filtros viven FUERA de la lista para no perder el foco
    // al buscar.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _busquedaController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar rol por nombre',
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
                activa: _activo == null,
                onTap: () => _elegirEstado(null),
              ),
              _Pastilla(
                etiqueta: 'Activos',
                activa: _activo == true,
                onTap: () => _elegirEstado(true),
              ),
              _Pastilla(
                etiqueta: 'Inactivos',
                activa: _activo == false,
                onTap: () => _elegirEstado(false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListaPaginada<Rol>(
            key: _listaKey,
            cargar: (pagina) => _servicio.roles(
              pagina: pagina,
              busqueda: _busqueda.isEmpty ? null : _busqueda,
              activo: _activo,
            ),
            mensajeError: 'No fue posible recuperar el listado de roles.',
            mensajeVacio: _hayFiltros
                ? 'No se encontraron roles para los criterios seleccionados.'
                : 'Aún no hay roles definidos.',
            iconoVacio: Icons.badge_outlined,
            separador: false,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemBuilder: (contexto, rol) =>
                TarjetaRol(rol: rol, onCambio: recargar),
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
