import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/permisos.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/personal.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/personal_service.dart';

/// HU15 - Retirar rol a un usuario. Fila de un rol dentro de la seccion "Roles"
/// de la ficha del usuario (screens/staff/detalle_usuario.dart).
///
/// Muestra el nombre del rol (con etiquetas si es de sistema o esta inactivo) y,
/// con el permiso `core:asignaciones:eliminar`, un boton para retirarlo. Pide
/// confirmacion y llama a `PersonalService.revocarRol`.
///
/// Reglas (las impone el backend; aqui se muestran sus mensajes):
///   - el usuario debe conservar al menos un rol;
///   - no se puede retirar TENANT_ADMIN al unico administrador activo.
/// Si el usuario se retira un rol a si mismo, se refresca su contexto para que
/// la interfaz refleje de inmediato lo que ya no puede hacer.
class FilaRolUsuario extends StatefulWidget {
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
  State<FilaRolUsuario> createState() => _FilaRolUsuarioState();
}

class _FilaRolUsuarioState extends State<FilaRolUsuario> {
  static const _errorGeneral = 'No fue posible retirar el rol del usuario.';
  static const _unicoRol = 'El usuario debe conservar al menos un rol.';

  final _servicio = PersonalService();
  bool _ocupado = false;

  void _avisar(String mensaje, {bool exito = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: exito ? AppColors.success : AppColors.primary,
        content: Text(mensaje, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<bool> _confirmar() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirar rol'),
        content: Text(
          'A ${widget.usuario.nombreCompleto} se le retirará el rol '
          '"${widget.rol.nombre}" y dejará de recibir sus permisos de '
          'inmediato.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Retirar',
              style: TextStyle(color: AppColors.primaryLight),
            ),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  Future<void> _retirar() async {
    // El backend tambien lo impide; se avisa aqui para ahorrar el viaje.
    if (widget.esUnico) {
      _avisar(_unicoRol);
      return;
    }
    if (!await _confirmar() || !mounted) return;

    final auth = context.read<AuthProvider>();
    setState(() => _ocupado = true);
    try {
      final resultantes = await _servicio.revocarRol(
        widget.usuario.id,
        widget.rol.id,
      );
      if (!mounted) return;
      if (auth.contexto?.usuario.id == widget.usuario.id) {
        await auth.recargarPerfil();
      }
      if (!mounted) return;
      _avisar('Rol retirado correctamente.', exito: true);
      widget.onRoles(resultantes);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Las reglas de negocio (ultimo rol, ultimo administrador) y los permisos
      // traen un mensaje especifico; el resto usa el texto general.
      _avisar(
        e.esReglaDeNegocio || e.esPermisoDenegado ? e.mensaje : _errorGeneral,
      );
    } catch (_) {
      if (!mounted) return;
      _avisar(_errorGeneral);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final puedeRetirar = auth.puede(Permisos.asignacionesEliminar);
    final rol = widget.rol;

    return ListTile(
      dense: true,
      leading: Icon(
        rol.esSistema ? Icons.shield_outlined : Icons.badge_outlined,
        size: 20,
        color: rol.esSistema ? AppColors.primaryLight : AppColors.grey,
      ),
      title: Text(
        rol.nombre,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: rol.activo ? AppColors.black : AppColors.grey,
        ),
      ),
      subtitle: rol.esSistema || !rol.activo
          ? Text(
              [
                if (rol.esSistema) 'Rol de sistema',
                if (!rol.activo) 'Inactivo: no concede permisos',
              ].join(' · '),
              style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
            )
          : null,
      trailing: !puedeRetirar
          ? null
          : _ocupado
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              tooltip: widget.esUnico ? _unicoRol : 'Retirar rol',
              icon: Icon(
                Icons.remove_circle_outline,
                size: 22,
                color: widget.esUnico ? AppColors.grey : AppColors.primaryLight,
              ),
              onPressed: _retirar,
            ),
    );
  }
}
