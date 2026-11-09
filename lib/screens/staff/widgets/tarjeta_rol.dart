import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../models/personal.dart';
import 'accion_editar_rol.dart';
import 'accion_eliminar_rol.dart';

/// HU11 - Tarjeta de un rol: nombre, estado, contador de usuarios y sus
/// permisos agrupados por dominio.
///
/// Guia: tarjeta desplegable (`ExpansionTile`) que al abrirse lista los
/// permisos por dominio (`Rol.permisosPorDominio`), marca los inertes
/// (`PermisoRol.inerte`, de modulos desactivados), muestra
/// `Rol.usuariosAsignados` y trata distinto al rol de sistema (`Rol.accesoTotal`:
/// no tiene lista de permisos porque autoriza todo).
///
/// IMPORTANTE: al reemplazar este archivo, NO quitar las dos filas de accion del
/// final (`AccionEditarRol` y `AccionEliminarRol`): son de HU12 y HU13 y viven en
/// sus propios archivos. Conservar tambien el nombre y los parametros de
/// `TarjetaRol`, que usa `RolesTab`.
class TarjetaRol extends StatelessWidget {
  const TarjetaRol({super.key, required this.rol, required this.onCambio});

  final Rol rol;

  /// Se llama cuando una accion modifico el rol, para recargar la lista.
  final VoidCallback onCambio;

  @override
  Widget build(BuildContext context) {
    // TODO(HU11): reemplazar este marcador por la tarjeta completa.
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(rol.nombre),
            subtitle: Text('${rol.usuariosAsignados} usuarios'),
          ),
          // Filas de accion (HU12 y HU13). No quitar.
          AccionEditarRol(rol: rol, onEditado: onCambio),
          AccionEliminarRol(rol: rol, onCambio: onCambio),
        ],
      ),
    );
  }
}
