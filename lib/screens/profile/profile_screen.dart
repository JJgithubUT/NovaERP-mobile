import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

/// Perfil de la sesion en curso, con los datos reales de `/api/core/me/`.
///
/// No navega al cerrar sesion: al limpiarse el estado, AuthGate devuelve
/// automaticamente a la pantalla de login.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final contexto = auth.contexto;
    final usuario = contexto?.usuario;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.black,
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: const Text(
          'Mi perfil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        usuario?.iniciales ?? '?',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    usuario?.nombreCompleto ?? 'Nombre no disponible',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contexto?.rolPrincipal ?? 'Sin rol',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            _Titulo('Información de la cuenta'),
            const SizedBox(height: 12),
            _Tarjeta(
              children: [
                _Fila(
                  icono: Icons.email_outlined,
                  titulo: 'Correo electrónico',
                  valor: usuario?.correo ?? '—',
                ),
                const _Separador(),
                _Fila(
                  icono: Icons.business_outlined,
                  titulo: 'Empresa',
                  valor: contexto?.tenant.razonSocial ?? '—',
                ),
                const _Separador(),
                _Fila(
                  icono: Icons.badge_outlined,
                  titulo: 'Estado de la cuenta',
                  valor: usuario?.estado ?? '—',
                ),
                const _Separador(),
                _Fila(
                  icono: Icons.schedule_outlined,
                  titulo: 'Último acceso',
                  valor: _formatearFecha(usuario?.ultimoAcceso),
                ),
              ],
            ),

            const SizedBox(height: 28),
            _Titulo('Seguridad'),
            const SizedBox(height: 12),
            _Tarjeta(
              children: [
                _Fila(
                  icono: Icons.shield_outlined,
                  titulo: 'Verificación en dos pasos',
                  valor: (usuario?.mfaEnrolado ?? false)
                      ? 'Activa'
                      : 'Pendiente de configurar',
                ),
                const _Separador(),
                ListTile(
                  leading: const Icon(
                    Icons.devices_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Sesiones activas',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.grey,
                    size: 14,
                  ),
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.sesiones,
                  ),
                ),
              ],
            ),

            // Los permisos son largos; se muestran plegados para quien necesite
            // comprobar por que ve (o no ve) una seccion.
            if (contexto != null && contexto.permisos.isNotEmpty) ...[
              const SizedBox(height: 28),
              _Tarjeta(
                children: [
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: const Icon(
                        Icons.key_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Mis permisos',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      subtitle: Text(
                        '${contexto.permisos.length} permisos vigentes',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final codigo in contexto.permisos.toList()
                              ..sort())
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  codigo,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),
            _BotonCerrarSesion(cargando: auth.cargando),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Primer acceso';
    final local = fecha.toLocal();
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(local.day)}/${dos(local.month)}/${local.year} '
        '${dos(local.hour)}:${dos(local.minute)}';
  }
}

class _BotonCerrarSesion extends StatelessWidget {
  const _BotonCerrarSesion({required this.cargando});

  final bool cargando;

  /// Pide confirmacion y cierra la sesion. El provider cierra en el
  /// dispositivo aunque el servidor no responda, asi que no hay error que mostrar.
  Future<void> _confirmar(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    await auth.cerrarSesion();
    // Sin navegacion: AuthGate reacciona al cambio de estado.
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: cargando ? null : () => _confirmar(context),
          splashColor: AppColors.primaryLight.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDF2F3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: AppColors.primaryLight,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (cargando)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.grey,
                    size: 14,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(children: children),
    );
  }
}

class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    color: AppColors.background,
    indent: 56,
  );
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icono, color: AppColors.black.withValues(alpha: 0.7)),
      title: Text(
        titulo,
        style: const TextStyle(fontSize: 13, color: AppColors.grey),
      ),
      subtitle: Text(
        valor,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.black,
        ),
      ),
    );
  }
}
