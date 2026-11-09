import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../models/personal.dart';
import 'accion_editar_rol.dart';
import 'accion_eliminar_rol.dart';

/// HU11 - Tarjeta de un rol: nombre, estado, contador de usuarios y sus
/// permisos agrupados por dominio.
///
/// Al abrirse lista los permisos por dominio, marca los inertes (de modulos que
/// la empresa tiene desactivados: se conservan pero no aplican) y trata aparte
/// al rol de sistema, que no tiene lista de permisos porque autoriza todo.
///
/// Al final de la tarjeta van las acciones de HU12 (editar) y HU13 (eliminar o
/// desactivar), cada una en su propio archivo. NO quitar esas dos filas.
class TarjetaRol extends StatelessWidget {
  const TarjetaRol({super.key, required this.rol, required this.onCambio});

  final Rol rol;

  /// Se llama cuando una accion modifico el rol, para recargar la lista.
  final VoidCallback onCambio;

  String get _resumen {
    final usuarios = rol.usuariosAsignados == 1
        ? '1 usuario'
        : '${rol.usuariosAsignados} usuarios';
    if (rol.accesoTotal) return 'Acceso total · $usuarios';
    final permisos = rol.totalPermisos == 1
        ? '1 permiso'
        : '${rol.totalPermisos} permisos';
    return '$permisos · $usuarios';
  }

  @override
  Widget build(BuildContext context) {
    final destacado = rol.accesoTotal ? AppColors.primaryLight : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: destacado.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              rol.accesoTotal ? Icons.shield : Icons.badge_outlined,
              size: 20,
              color: destacado,
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  rol.nombre,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: rol.activo ? AppColors.black : AppColors.grey,
                  ),
                ),
              ),
              if (rol.esSistema) ...[
                const SizedBox(width: 6),
                const _Etiqueta(texto: 'Sistema', color: AppColors.primaryLight),
              ],
              if (!rol.activo) ...[
                const SizedBox(width: 6),
                const _Etiqueta(texto: 'Inactivo', color: AppColors.grey),
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              _resumen,
              style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            if (rol.accesoTotal)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rol de sistema: autoriza todo lo que la empresa tenga '
                  'contratado, sin lista de permisos. No se puede editar ni '
                  'desactivar.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.grey,
                    height: 1.4,
                  ),
                ),
              )
            else if (rol.permisosPorDominio.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sin permisos asignados: quien tenga solo este rol no podrá '
                  'hacer nada.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.warning),
                ),
              )
            else ...[
              if (!rol.activo)
                const _Aviso(
                  'Rol inactivo: no se puede asignar a nuevos usuarios y no '
                  'concede ningún permiso hasta que se reactive.',
                ),
              if (rol.permisosInertes > 0)
                _Aviso(
                  '${rol.permisosInertes} permisos están inactivos porque su '
                  'módulo no está habilitado en la empresa. Se conservan y '
                  'volverán a aplicar si se contrata.',
                ),
              for (final dominio in rol.permisosPorDominio.keys.toList()..sort())
                _GrupoDominio(
                  dominio: dominio,
                  permisos: rol.permisosPorDominio[dominio]!,
                ),
            ],

            const Divider(height: 24),
            // Filas de accion (HU12 y HU13). No quitar.
            AccionEditarRol(rol: rol, onEditado: onCambio),
            AccionEliminarRol(rol: rol, onCambio: onCambio),
          ],
        ),
      ),
    );
  }
}

class _GrupoDominio extends StatelessWidget {
  const _GrupoDominio({required this.dominio, required this.permisos});

  final String dominio;
  final List<PermisoRol> permisos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${dominio.toUpperCase()} · ${permisos.length}',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: AppColors.grey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final permiso in permisos)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: permiso.inerte
                        ? AppColors.grey.withValues(alpha: 0.12)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${permiso.recurso}:${permiso.accion}',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: permiso.inerte ? AppColors.grey : AppColors.black,
                      decoration: permiso.inerte
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 11.5,
          color: AppColors.black,
          height: 1.35,
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
