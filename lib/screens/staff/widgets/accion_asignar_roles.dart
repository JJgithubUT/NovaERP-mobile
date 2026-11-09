import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/permisos.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/accion_tile.dart';
import '../../../models/personal.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/personal_service.dart';

/// HU14 - Vincular roles a un usuario. Fila de accion de la seccion "Roles" de
/// la ficha del usuario (screens/staff/detalle_usuario.dart).
///
/// Solo se muestra con el permiso `core:asignaciones:crear`. Abre un selector
/// con los roles ACTIVOS del tenant que el usuario todavia no tiene; se pueden
/// elegir varios. Los privilegios del usuario son la union de los permisos de
/// todos sus roles (lo resuelve el backend).
///
/// El backend rechaza roles inactivos o de otro tenant, y el conjunto que
/// mezcla el rol Auditor con permisos de creacion, edicion o eliminacion; su
/// mensaje se muestra tal cual. Error general: "No fue posible asignar los roles
/// al usuario."
class AccionAsignarRoles extends StatefulWidget {
  const AccionAsignarRoles({
    super.key,
    required this.usuario,
    required this.rolesActuales,
    required this.onRoles,
  });

  final UsuarioDirectorio usuario;

  /// Roles que el usuario tiene ahora.
  final List<RolAsignado> rolesActuales;

  /// Se llama con la lista resultante tras asignar.
  final ValueChanged<List<RolAsignado>> onRoles;

  @override
  State<AccionAsignarRoles> createState() => _AccionAsignarRolesState();
}

class _AccionAsignarRolesState extends State<AccionAsignarRoles> {
  static const _errorGeneral = 'No fue posible asignar los roles al usuario.';

  final _servicio = PersonalService();
  bool _ocupado = false;

  void _avisar(String mensaje, {bool exito = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: exito ? AppColors.success : AppColors.primary,
        content: Text(mensaje, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _asignar() async {
    final auth = context.read<AuthProvider>();
    setState(() => _ocupado = true);
    try {
      // CU1: el selector solo lista roles activos del tenant.
      final activos = await _servicio.rolesActivos();
      if (!mounted) return;
      final yaTiene = widget.rolesActuales.map((r) => r.id).toSet();
      final disponibles = activos.where((r) => !yaTiene.contains(r.id)).toList();

      if (disponibles.isEmpty) {
        _avisar('El usuario ya tiene todos los roles activos disponibles.');
        return;
      }

      final elegidos = await showModalBottomSheet<Set<String>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _HojaRoles(disponibles: disponibles),
      );
      if (elegidos == null || elegidos.isEmpty || !mounted) return;

      final resultantes = await _servicio.asignarRoles(
        widget.usuario.id,
        elegidos.toList(),
      );
      if (!mounted) return;
      if (auth.contexto?.usuario.id == widget.usuario.id) {
        await auth.recargarPerfil();
      }
      if (!mounted) return;
      _avisar(
        elegidos.length == 1
            ? 'Rol asignado correctamente.'
            : 'Roles asignados correctamente.',
        exito: true,
      );
      widget.onRoles(resultantes);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Reglas de negocio (rol inactivo, Auditor con permisos de mutacion) y
      // permisos traen un mensaje especifico; el resto usa el texto general.
      _avisar(
        e.esReglaDeNegocio || e.esPermisoDenegado ? e.mensaje : _errorGeneral,
      );
    } catch (_) {
      if (!mounted) return;
      _avisar(_errorGeneral);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.puede(Permisos.asignacionesCrear)) {
      return const SizedBox.shrink();
    }

    return AccionTile(
      icono: Icons.person_add_alt_outlined,
      etiqueta: 'Asignar roles',
      detalle: 'Suma los permisos de los roles elegidos',
      deshabilitado: _ocupado,
      onTap: _asignar,
    );
  }
}

/// Hoja inferior con los roles asignables y casillas para elegir varios.
class _HojaRoles extends StatefulWidget {
  const _HojaRoles({required this.disponibles});

  final List<Rol> disponibles;

  @override
  State<_HojaRoles> createState() => _HojaRolesState();
}

class _HojaRolesState extends State<_HojaRoles> {
  final _elegidos = <String>{};

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Asignar roles',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Solo se muestran los roles activos que el usuario aún no tiene.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.grey),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final rol in widget.disponibles)
                    CheckboxListTile(
                      activeColor: AppColors.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _elegidos.contains(rol.id),
                      onChanged: (v) => setState(() {
                        v == true ? _elegidos.add(rol.id) : _elegidos.remove(rol.id);
                      }),
                      title: Text(rol.nombre),
                      subtitle: Text(
                        rol.accesoTotal
                            ? 'Acceso total'
                            : '${rol.totalPermisos == 1 ? '1 permiso' : '${rol.totalPermisos} permisos'} · '
                                  '${rol.usuariosAsignados == 1 ? '1 usuario' : '${rol.usuariosAsignados} usuarios'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _elegidos.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(_elegidos),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _elegidos.isEmpty
                            ? 'Asignar'
                            : 'Asignar (${_elegidos.length})',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
