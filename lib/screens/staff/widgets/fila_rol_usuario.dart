import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../models/personal.dart';

/// HU15 - Retirar rol a un usuario. Fila de un rol dentro de la seccion "Roles"
/// de la ficha del usuario (screens/staff/detalle_usuario.dart).
///
/// Guia: mostrar el nombre del [rol] (y si es de sistema o esta inactivo) con un
/// boton para retirarlo, solo con `AuthProvider.puede(Permisos.asignacionesEliminar)`.
/// Pedir confirmacion, llamar a `PersonalService.revocarRol` y avisar con
/// [onRoles] pasando la lista resultante.
///
/// Reglas del backend (mostrar su mensaje): el usuario debe conservar al menos
/// un rol ([esUnico] permite deshabilitar el boton con "El usuario debe
/// conservar al menos un rol.") y no se puede retirar TENANT_ADMIN al unico
/// administrador activo. Error general: "No fue posible retirar el rol del
/// usuario." Si el usuario se retira un rol a si mismo, refrescar su contexto
/// con `AuthProvider.recargarPerfil`.
///
/// Contrato que usa la ficha: conservar el nombre de la clase y sus
/// parametros.
class FilaRolUsuario extends StatelessWidget {
  const FilaRolUsuario({
    super.key,
    required this.usuario,
    required this.rol,
    required this.esUnico,
    required this.onRoles,
  });

  final UsuarioDirectorio usuario;
  final RolAsignado rol;

  /// El usuario solo tiene este rol.
  final bool esUnico;

  /// Se llama con la lista resultante tras retirar el rol.
  final ValueChanged<List<RolAsignado>> onRoles;

  @override
  Widget build(BuildContext context) {
    // TODO(HU15): agregar el boton de retirar.
    return ListTile(
      dense: true,
      leading: const Icon(Icons.badge_outlined, size: 20, color: AppColors.grey),
      title: Text(
        rol.nombre,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
