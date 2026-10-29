import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/permisos.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/accion_tile.dart';
import '../../../models/personal.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/personal_service.dart';

/// HU08 - Suspender o reactivar usuario. Fila de accion de la ficha.
///
/// Solo se muestra con el permiso `core:usuarios:suspender`. Pide confirmacion
/// explicita antes de cambiar el estado. El cierre de las sesiones activas al
/// suspender lo hace el backend.
///
/// Un usuario no puede suspenderse a si mismo: seria cerrarse la puerta desde
/// dentro.
class AccionSuspension extends StatefulWidget {
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
  State<AccionSuspension> createState() => _AccionSuspensionState();
}

class _AccionSuspensionState extends State<AccionSuspension> {
  final _servicio = PersonalService();
  bool _ocupado = false;

  bool get _suspendido => widget.estado.toLowerCase() == 'suspendido';

  Future<bool> _confirmar() async {
    final u = widget.usuario;
    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_suspendido ? 'Reactivar usuario' : 'Suspender usuario'),
        content: Text(
          _suspendido
              ? '${u.nombreCompleto} podrá volver a ingresar de inmediato.'
              : '${u.nombreCompleto} no podrá ingresar y se cerrarán todas '
                    'sus sesiones abiertas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              _suspendido ? 'Reactivar' : 'Suspender',
              style: const TextStyle(color: AppColors.primaryLight),
            ),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  void _avisar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(mensaje, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _cambiarEstado() async {
    if (!await _confirmar() || !mounted) return;

    final reactivar = _suspendido;
    setState(() => _ocupado = true);
    try {
      if (reactivar) {
        await _servicio.reactivar(widget.usuario.id);
      } else {
        await _servicio.suspender(widget.usuario.id);
      }
      if (!mounted) return;
      widget.onEstadoCambiado(reactivar ? 'activo' : 'suspendido');
      _avisar(
        'Estado del usuario actualizado correctamente.',
        AppColors.success,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _avisar(e.mensaje, AppColors.primary);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.puede(Permisos.usuariosSuspender)) {
      return const SizedBox.shrink();
    }

    final esUnoMismo = auth.contexto?.usuario.id == widget.usuario.id;

    return AccionTile(
      icono: _suspendido
          ? Icons.play_circle_outline
          : Icons.pause_circle_outline,
      etiqueta: _suspendido ? 'Reactivar usuario' : 'Suspender usuario',
      detalle: _suspendido
          ? 'Podrá volver a ingresar; conserva sus roles'
          : 'Cierra sus sesiones y bloquea su acceso',
      deshabilitado: _ocupado || (esUnoMismo && !_suspendido),
      peligrosa: !_suspendido,
      onTap: _cambiarEstado,
    );
  }
}
