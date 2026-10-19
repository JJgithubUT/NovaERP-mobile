import 'package:flutter/material.dart';

import '../../../core/widgets/accion_tile.dart';
import '../../../models/personal.dart';

/// HU08 - Suspender o reactivar usuario.
///
/// Fila de accion de la ficha del usuario. Guia: pedir confirmacion explicita
/// antes de suspender, llamar a `PersonalService.suspender` / `reactivar`, y
/// avisar con "Estado del usuario actualizado correctamente.". Mostrar solo si
/// `AuthProvider.puede(Permisos.usuariosSuspender)` y no permitir que alguien se
/// suspenda a si mismo. Si el servidor rechaza, mostrar `ApiException.mensaje`.
///
/// Contrato que usa la ficha (detalle_usuario.dart): conservar el nombre de la
/// clase y sus tres parametros. Al cambiar el estado, llamar
/// [onEstadoCambiado] con el nuevo ('activo' o 'suspendido').
class AccionSuspension extends StatelessWidget {
  const AccionSuspension({
    super.key,
    required this.usuario,
    required this.estado,
    required this.onEstadoCambiado,
  });

  final UsuarioDirectorio usuario;

  /// Estado actual en pantalla (puede haber cambiado desde que se abrio).
  final String estado;
  final ValueChanged<String> onEstadoCambiado;

  @override
  Widget build(BuildContext context) {
    // TODO(HU08): implementar la accion.
    return const AccionTile(
      icono: Icons.pause_circle_outline,
      etiqueta: 'Suspender o reactivar',
      detalle: 'HU08 pendiente',
      onTap: _sinAccion,
      deshabilitado: true,
    );
  }

  static void _sinAccion() {}
}
