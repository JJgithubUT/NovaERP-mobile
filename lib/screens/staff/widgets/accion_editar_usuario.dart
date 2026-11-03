import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/permisos.dart';
import '../../../core/widgets/accion_tile.dart';
import '../../../models/personal.dart';
import '../../../providers/auth_provider.dart';
import '../forms/editar_usuario_form.dart';

/// HU07 - Editar usuario. Fila de accion de la ficha del usuario.
///
/// Solo se muestra con el permiso `core:usuarios:editar`. Tras guardar llama a
/// [onEditado]: la ficha vuelve al directorio, que se recarga.
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
    final auth = context.watch<AuthProvider>();
    if (!auth.puede(Permisos.usuariosEditar)) return const SizedBox.shrink();

    return AccionTile(
      icono: Icons.edit_outlined,
      etiqueta: 'Editar usuario',
      detalle: 'Correo, nombre, teléfono, puesto y departamento',
      onTap: () async {
        final guardado = await abrirEdicionUsuario(context, usuario);
        if (guardado) onEditado();
      },
    );
  }
}
