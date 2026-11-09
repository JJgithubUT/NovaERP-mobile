import 'package:flutter/material.dart';

import '../../models/personal.dart';
import '../config/app_colors.dart';

/// Selector de permisos agrupado por dominio, para crear o editar un rol.
///
/// Solo ofrece los permisos del catalogo maestro (`GET /api/core/permisos/`):
/// no se pueden inventar. Los de modulos que la empresa no tiene activos
/// (`inerte`) se muestran deshabilitados con su motivo, en vez de ocultarse,
/// para que el administrador entienda por que no puede elegirlos.
///
/// Es un widget sin estado propio: quien lo usa guarda el conjunto de
/// [seleccionados] y lo actualiza en [onCambio].
class SelectorPermisos extends StatelessWidget {
  const SelectorPermisos({
    super.key,
    required this.catalogo,
    required this.seleccionados,
    required this.onCambio,
    this.habilitado = true,
    this.resaltado = false,
  });

  final List<DominioPermisos> catalogo;

  /// Codigos de los permisos elegidos.
  final Set<String> seleccionados;
  final ValueChanged<Set<String>> onCambio;
  final bool habilitado;

  /// Pinta el borde cuando el backend senala 'permisos' como causa del error.
  final bool resaltado;

  void _alternar(String codigo, bool elegido) {
    final nuevo = Set<String>.of(seleccionados);
    elegido ? nuevo.add(codigo) : nuevo.remove(codigo);
    onCambio(nuevo);
  }

  void _marcarDominio(DominioPermisos dominio, bool elegir) {
    final nuevo = Set<String>.of(seleccionados);
    for (final p in dominio.permisos.where((p) => !p.inerte)) {
      elegir ? nuevo.add(p.codigo) : nuevo.remove(p.codigo);
    }
    onCambio(nuevo);
  }

  @override
  Widget build(BuildContext context) {
    if (catalogo.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No hay permisos disponibles en el catálogo.',
          style: TextStyle(fontSize: 12.5, color: AppColors.warning),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: resaltado
              ? AppColors.primary
              : AppColors.grey.withValues(alpha: 0.3),
          width: resaltado ? 1.5 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Column(
          children: [
            for (final dominio in catalogo)
              _GrupoDominio(
                dominio: dominio,
                seleccionados: seleccionados,
                habilitado: habilitado,
                onAlternar: _alternar,
                onMarcarTodo: (elegir) => _marcarDominio(dominio, elegir),
              ),
          ],
        ),
      ),
    );
  }
}

class _GrupoDominio extends StatelessWidget {
  const _GrupoDominio({
    required this.dominio,
    required this.seleccionados,
    required this.habilitado,
    required this.onAlternar,
    required this.onMarcarTodo,
  });

  final DominioPermisos dominio;
  final Set<String> seleccionados;
  final bool habilitado;
  final void Function(String codigo, bool elegido) onAlternar;
  final ValueChanged<bool> onMarcarTodo;

  @override
  Widget build(BuildContext context) {
    final elegibles = dominio.permisos.where((p) => !p.inerte).toList();
    final elegidos = elegibles
        .where((p) => seleccionados.contains(p.codigo))
        .length;
    final todos = elegibles.isNotEmpty && elegidos == elegibles.length;

    return ExpansionTile(
      // Abierto de entrada si ya tiene algo marcado (al editar un rol).
      initiallyExpanded: elegidos > 0,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        dominio.dominio.toUpperCase(),
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: AppColors.black,
        ),
      ),
      subtitle: Text(
        '$elegidos de ${elegibles.length} seleccionados',
        style: TextStyle(
          fontSize: 11.5,
          color: elegidos > 0 ? AppColors.primary : AppColors.grey,
        ),
      ),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        if (elegibles.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: habilitado ? () => onMarcarTodo(!todos) : null,
                child: Text(
                  todos ? 'Quitar todos' : 'Seleccionar todos',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        for (final permiso in dominio.permisos)
          CheckboxListTile(
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primary,
            value: seleccionados.contains(permiso.codigo),
            onChanged: habilitado && !permiso.inerte
                ? (v) => onAlternar(permiso.codigo, v ?? false)
                : null,
            title: Text(
              '${permiso.recurso} · ${permiso.accion}',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: permiso.inerte ? AppColors.grey : AppColors.black,
              ),
            ),
            subtitle: Text(
              permiso.inerte
                  ? 'Su módulo no está activo en la empresa'
                  : permiso.descripcion,
              style: TextStyle(
                fontSize: 11.5,
                color: permiso.inerte ? AppColors.warning : AppColors.grey,
              ),
            ),
          ),
      ],
    );
  }
}
