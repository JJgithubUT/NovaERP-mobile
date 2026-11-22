import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/permisos.dart';
import '../../../core/widgets/accion_tile.dart';
import '../../../models/personal.dart';
import '../../../providers/auth_provider.dart';
import '../forms/editar_rol_form.dart';

/// HU12 - Modificar permisos de un rol existente. Fila de accion de la tarjeta
/// del rol (widgets/tarjeta_rol.dart).
///
/// Solo se muestra con el permiso `core:roles:editar`. El rol de sistema
/// (TENANT_ADMIN) se muestra deshabilitado: el backend lo rechazaria con 403.
/// Tras guardar llama a [onEditado] y, si el rol editado es uno de los del
/// usuario en sesion, refresca su contexto para que la interfaz refleje de
/// inmediato los permisos nuevos.
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
    final auth = context.watch<AuthProvider>();
    if (!auth.puede(Permisos.rolesEditar)) return const SizedBox.shrink();

    if (rol.esSistema) {
      return const AccionTile(
        icono: Icons.edit_off_outlined,
        etiqueta: 'Editar permisos',
        detalle: 'Este rol de sistema no puede modificarse.',
        onTap: _sinAccion,
        deshabilitado: true,
      );
    }

    return AccionTile(
      icono: Icons.edit_outlined,
      etiqueta: 'Editar rol',
      detalle: 'Nombre y permisos',
      onTap: () async {
        final proveedor = context.read<AuthProvider>();
        final guardado = await abrirEdicionRol(context, rol);
        if (!guardado) return;
        // Si se edito un rol propio, los permisos del usuario en sesion cambian.
        if (proveedor.contexto?.roles.contains(rol.nombre) ?? false) {
          await proveedor.recargarPerfil();
        }
        onEditado();
      },
    );
  }

  static void _sinAccion() {}
}
