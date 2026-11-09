import 'package:flutter/material.dart';

import '../../../core/widgets/accion_tile.dart';
import '../../../models/personal.dart';

/// HU14 - Vincular roles a un usuario. Fila de accion de la seccion "Roles" de
/// la ficha del usuario (screens/staff/detalle_usuario.dart).
///
/// Guia: al tocarla mostrar un selector con los roles ACTIVOS del tenant
/// (`PersonalService.rolesActivos`) que el usuario todavia no tiene
/// ([rolesActuales]), asignar los elegidos con `PersonalService.asignarRoles` y
/// avisar con [onRoles] pasando la lista resultante. Mostrar solo con
/// `AuthProvider.puede(Permisos.asignacionesCrear)`.
///
/// Errores: el backend rechaza roles inactivos o de otro tenant y el conjunto
/// que mezcla el rol Auditor con permisos de mutacion (mostrar su mensaje);
/// error general: "No fue posible asignar los roles al usuario."
///
/// Contrato que usa la ficha: conservar el nombre de la clase y sus
/// parametros.
class AccionAsignarRoles extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // TODO(HU14): implementar la accion.
    return const AccionTile(
      icono: Icons.person_add_alt_outlined,
      etiqueta: 'Asignar roles',
      detalle: 'HU14 pendiente',
      onTap: _sinAccion,
      deshabilitado: true,
    );
  }

  static void _sinAccion() {}
}
