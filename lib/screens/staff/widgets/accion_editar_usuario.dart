import 'package:flutter/material.dart';

import '../../../core/widgets/accion_tile.dart';
import '../../../models/personal.dart';

/// HU07 - Editar usuario.
///
/// Fila de accion de la ficha del usuario. Guia: al tocarla abrir un formulario
/// precargado con los datos vigentes (puedes crearlo en forms/editar_usuario_form.dart
/// y reutilizar `CampoFormulario` de core/widgets), pedir confirmacion explicita
/// antes de guardar, enviar solo lo que cambio con `PersonalService.editarUsuario`
/// y, si cambio el correo, mostrar el token con `mostrarEnlaceActivacion`
/// (widgets/enlace_activacion.dart). Mostrar solo si
/// `AuthProvider.puede(Permisos.usuariosEditar)`.
///
/// Contrato que usa la ficha (detalle_usuario.dart): conservar el nombre de la
/// clase y sus parametros. Tras guardar, llamar [onEditado] para que la ficha y
/// el directorio se recarguen.
class AccionEditarUsuario extends StatelessWidget {
  const AccionEditarUsuario({
    super.key,
    required this.usuario,
    required this.onEditado,
  });

  final UsuarioDirectorio usuario;
  final VoidCallback onEditado;

  @override
  Widget build(BuildContext context) {
    // TODO(HU07): implementar la accion.
    return const AccionTile(
      icono: Icons.edit_outlined,
      etiqueta: 'Editar usuario',
      detalle: 'HU07 pendiente',
      onTap: _sinAccion,
      deshabilitado: true,
    );
  }

  static void _sinAccion() {}
}
