import 'package:flutter/material.dart';

import '../../../core/widgets/accion_tile.dart';
import '../../../models/personal.dart';

/// HU13 - Eliminar o desactivar un rol personalizado. Fila de accion de la
/// tarjeta del rol (widgets/tarjeta_rol.dart).
///
/// Guia: pedir confirmacion y llamar a `PersonalService.desactivarRol`. Si el
/// rol tiene usuarios asignados el backend responde 422 (campo 'rol') con
/// "Este rol tiene N usuarios asignados. Reasignelos antes de eliminarlo, o
/// desactive el rol."; mostrar ese mensaje y ofrecer "Desactivar", que repite
/// la llamada con `confirmado: true`. Si el rol ya esta inactivo, ofrecer
/// `PersonalService.reactivarRol`. Mostrar solo con
/// `AuthProvider.puede(Permisos.rolesEliminar)`.
///
/// Criterios: el rol de sistema (`Rol.accesoTotal`) no se elimina ni se
/// desactiva; error general: "No fue posible eliminar el rol." Tras cambiar el
/// estado, llamar a [onCambio].
///
/// Contrato que usa la tarjeta: conservar el nombre de la clase y sus
/// parametros.
class AccionEliminarRol extends StatelessWidget {
  const AccionEliminarRol({
    super.key,
    required this.rol,
    required this.onCambio,
  });

  final Rol rol;
  final VoidCallback onCambio;

  @override
  Widget build(BuildContext context) {
    // TODO(HU13): implementar la accion.
    return const AccionTile(
      icono: Icons.delete_outline,
      etiqueta: 'Eliminar o desactivar',
      detalle: 'HU13 pendiente',
      onTap: _sinAccion,
      deshabilitado: true,
    );
  }

  static void _sinAccion() {}
}
