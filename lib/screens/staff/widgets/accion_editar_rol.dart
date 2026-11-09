import 'package:flutter/material.dart';

import '../../../core/widgets/accion_tile.dart';
import '../../../models/personal.dart';

/// HU12 - Modificar permisos de un rol existente. Fila de accion de la tarjeta
/// del rol (widgets/tarjeta_rol.dart).
///
/// Guia: al tocarla abrir un formulario con el nombre y el selector
/// `SelectorPermisos` (core/widgets) precargado con `Rol.codigosPermisos`
/// (puedes crearlo en forms/editar_rol_form.dart), guardar con
/// `PersonalService.editarRol` (el conjunto de permisos se envia completo) y
/// llamar a [onEditado]. Mostrar solo con
/// `AuthProvider.puede(Permisos.rolesEditar)`.
///
/// Criterios: el rol de sistema (`Rol.accesoTotal`) no se puede editar (el
/// backend responde 403 "Este rol de sistema no puede modificarse."); error
/// general: "No fue posible actualizar el rol."
///
/// Contrato que usa la tarjeta: conservar el nombre de la clase y sus
/// parametros.
class AccionEditarRol extends StatelessWidget {
  const AccionEditarRol({
    super.key,
    required this.rol,
    required this.onEditado,
  });

  final Rol rol;
  final VoidCallback onEditado;

  @override
  Widget build(BuildContext context) {
    // TODO(HU12): implementar la accion.
    return const AccionTile(
      icono: Icons.edit_outlined,
      etiqueta: 'Editar permisos',
      detalle: 'HU12 pendiente',
      onTap: _sinAccion,
      deshabilitado: true,
    );
  }

  static void _sinAccion() {}
}
