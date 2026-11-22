import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/permisos.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/accion_tile.dart';
import '../../../models/personal.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/personal_service.dart';

/// HU13 - Eliminar o desactivar un rol personalizado. Fila de accion de la
/// tarjeta del rol (widgets/tarjeta_rol.dart).
///
/// El backend nunca borra fisicamente: "eliminar" es una baja logica.
///   - Sin usuarios asignados se da de baja directamente.
///   - Con usuarios asignados el backend responde 422 (campo 'rol') con
///     "Este rol tiene N usuarios asignados. Reasignelos antes de eliminarlo, o
///     desactive el rol."; se muestra y se ofrece "Desactivar", que repite la
///     llamada con confirmacion.
///   - Un rol inactivo se puede reactivar.
///   - El rol de sistema (TENANT_ADMIN) no se elimina ni se desactiva.
///
/// Importante: un rol inactivo NO concede permisos. Quienes lo tenian dejan de
/// recibir lo que ese rol les daba (el rol y sus asignaciones se conservan, asi
/// que reactivarlo lo restituye).
///
/// Solo se muestra con `core:roles:eliminar` (y `core:roles:editar` para
/// reactivar). Tras cambiar el estado llama a [onCambio].
class AccionEliminarRol extends StatefulWidget {
  const AccionEliminarRol({
    super.key,
    required this.rol,
    required this.onCambio,
  });

  final Rol rol;
  final VoidCallback onCambio;

  @override
  State<AccionEliminarRol> createState() => _AccionEliminarRolState();
}

class _AccionEliminarRolState extends State<AccionEliminarRol> {
  static const _errorGeneral = 'No fue posible eliminar el rol.';

  final _servicio = PersonalService();
  bool _ocupado = false;

  Future<bool> _confirmar({
    required String titulo,
    required String detalle,
    required String accion,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(detalle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              accion,
              style: const TextStyle(color: AppColors.primaryLight),
            ),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  void _avisar(String mensaje, {bool exito = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: exito ? AppColors.success : AppColors.primary,
        content: Text(mensaje, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  /// Si el rol desactivado es uno de los del usuario en sesion, sus permisos
  /// cambian: se refresca el contexto para que la interfaz lo refleje.
  Future<void> _refrescarSiEsPropio() async {
    final auth = context.read<AuthProvider>();
    if (auth.contexto?.roles.contains(widget.rol.nombre) ?? false) {
      await auth.recargarPerfil();
    }
  }

  Future<void> _desactivar() async {
    final rol = widget.rol;
    if (!await _confirmar(
          titulo: 'Eliminar rol',
          detalle:
              'El rol "${rol.nombre}" se dará de baja: no podrá asignarse a '
              'nuevos usuarios y dejará de conceder permisos. Podrá '
              'reactivarse después.',
          accion: 'Eliminar',
        ) ||
        !mounted) {
      return;
    }

    setState(() => _ocupado = true);
    try {
      try {
        await _servicio.desactivarRol(rol.id);
      } on ApiException catch (e) {
        // Con usuarios asignados el backend exige confirmar la desactivacion.
        if (!(e.esReglaDeNegocio && e.campo == 'rol')) rethrow;
        if (!mounted) return;
        final confirmado = await _confirmar(
          titulo: 'Rol con usuarios asignados',
          detalle:
              '${e.mensaje}\n\nSi lo desactiva, esos usuarios dejarán de '
              'recibir los permisos de este rol de inmediato.',
          accion: 'Desactivar',
        );
        if (!confirmado || !mounted) return;
        await _servicio.desactivarRol(rol.id, confirmado: true);
      }
      if (!mounted) return;
      await _refrescarSiEsPropio();
      if (!mounted) return;
      _avisar('Rol desactivado correctamente.', exito: true);
      widget.onCambio();
    } on ApiException catch (e) {
      if (!mounted) return;
      _avisar(e.esPermisoDenegado ? e.mensaje : _errorGeneral);
    } catch (_) {
      if (!mounted) return;
      _avisar(_errorGeneral);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _reactivar() async {
    final rol = widget.rol;
    if (!await _confirmar(
          titulo: 'Reactivar rol',
          detalle:
              'El rol "${rol.nombre}" volverá a poder asignarse y a conceder '
              'sus permisos.',
          accion: 'Reactivar',
        ) ||
        !mounted) {
      return;
    }

    setState(() => _ocupado = true);
    try {
      await _servicio.reactivarRol(rol.id);
      if (!mounted) return;
      await _refrescarSiEsPropio();
      if (!mounted) return;
      _avisar('Rol reactivado correctamente.', exito: true);
      widget.onCambio();
    } on ApiException catch (e) {
      if (!mounted) return;
      _avisar(
        e.esPermisoDenegado ? e.mensaje : 'No fue posible reactivar el rol.',
      );
    } catch (_) {
      if (!mounted) return;
      _avisar('No fue posible reactivar el rol.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rol = widget.rol;

    if (!auth.puede(Permisos.rolesEliminar)) return const SizedBox.shrink();

    if (rol.esSistema) {
      return const AccionTile(
        icono: Icons.lock_outline,
        etiqueta: 'Eliminar o desactivar',
        detalle: 'Este rol de sistema no puede eliminarse ni desactivarse.',
        onTap: _sinAccion,
        deshabilitado: true,
      );
    }

    if (!rol.activo) {
      // Reactivar es una edicion (PATCH), asi que exige el permiso de editar.
      if (!auth.puede(Permisos.rolesEditar)) return const SizedBox.shrink();
      return AccionTile(
        icono: Icons.restore_outlined,
        etiqueta: 'Reactivar rol',
        detalle: 'Vuelve a poder asignarse y a conceder permisos',
        deshabilitado: _ocupado,
        onTap: _reactivar,
      );
    }

    return AccionTile(
      icono: Icons.delete_outline,
      etiqueta: 'Eliminar rol',
      detalle: rol.usuariosAsignados > 0
          ? 'Tiene ${rol.usuariosAsignados == 1 ? '1 usuario' : '${rol.usuariosAsignados} usuarios'}: '
                'se pedirá confirmar'
          : 'Se da de baja; puede reactivarse después',
      peligrosa: true,
      deshabilitado: _ocupado,
      onTap: _desactivar,
    );
  }

  static void _sinAccion() {}
}
