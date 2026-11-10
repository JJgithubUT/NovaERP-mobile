import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';
import '../../core/utils/formato.dart';
import '../../models/personal.dart';
import 'widgets/accion_editar_usuario.dart';
import 'widgets/accion_suspension.dart';

/// Ficha de un usuario con las acciones administrativas sobre el.
///
/// Devuelve true si algo cambio, para que el directorio se recargue.
///
/// Este archivo es BASE: ninguna HU necesita editarlo. Las acciones viven en
/// sus propios archivos y esta ficha solo las coloca:
///   HU07 -> widgets/accion_editar_usuario.dart
///   HU08 -> widgets/accion_suspension.dart
Future<bool> abrirDetalleUsuario(
  BuildContext context,
  UsuarioDirectorio usuario,
) async {
  final cambio = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => _DetalleUsuario(usuario: usuario)),
  );
  return cambio ?? false;
}

class _DetalleUsuario extends StatefulWidget {
  const _DetalleUsuario({required this.usuario});

  final UsuarioDirectorio usuario;

  @override
  State<_DetalleUsuario> createState() => _DetalleUsuarioState();
}

class _DetalleUsuarioState extends State<_DetalleUsuario> {
  late String _estado = widget.usuario.estado;
  bool _huboCambios = false;

  @override
  Widget build(BuildContext context) {
    final usuario = widget.usuario;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (yaSalio, _) {
        if (!yaSalio) Navigator.of(context).pop(_huboCambios);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Ficha del usuario',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_huboCambios),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      usuario.iniciales,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    usuario.nombreCompleto,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    usuario.correo,
                    style: const TextStyle(fontSize: 13, color: AppColors.grey),
                  ),
                  const SizedBox(height: 10),
                  _Insignia(estado: _estado),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _Seccion(
              titulo: 'Datos',
              hijos: [
                _Fila(
                  icono: Icons.work_outline,
                  titulo: 'Puesto',
                  valor: usuario.puesto ?? '—',
                ),
                _Fila(
                  icono: Icons.apartment_outlined,
                  titulo: 'Departamento',
                  valor: usuario.departamento ?? '—',
                ),
                _Fila(
                  icono: Icons.phone_outlined,
                  titulo: 'Teléfono',
                  valor: usuario.telefono ?? '—',
                ),
                _Fila(
                  icono: Icons.badge_outlined,
                  titulo: 'Roles',
                  valor: usuario.roles.isEmpty
                      ? 'Sin roles'
                      : usuario.roles.join(' · '),
                ),
                _Fila(
                  icono: Icons.schedule_outlined,
                  titulo: 'Último acceso',
                  valor: usuario.ultimoAcceso == null
                      ? 'Nunca ha ingresado'
                      : Formato.fechaHora(usuario.ultimoAcceso),
                ),
                _Fila(
                  icono: Icons.event_outlined,
                  titulo: 'Alta',
                  valor: Formato.fechaHora(usuario.creadoEn),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _Seccion(
              titulo: 'Acciones',
              hijos: [
                AccionEditarUsuario(
                  usuario: usuario,
                  // Los datos mostrados ya no son vigentes: se vuelve al
                  // directorio, que se recarga.
                  onEditado: () => Navigator.of(context).pop(true),
                ),
                AccionSuspension(
                  usuario: usuario,
                  estado: _estado,
                  onEstadoCambiado: (nuevo) => setState(() {
                    _estado = nuevo;
                    _huboCambios = true;
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- piezas UI

class _Insignia extends StatelessWidget {
  const _Insignia({required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final (color, etiqueta) = switch (estado.toLowerCase()) {
      'activo' => (AppColors.success, 'Activo'),
      'suspendido' => (AppColors.primaryLight, 'Suspendido'),
      'pendiente' => (AppColors.warning, 'Pendiente de activación'),
      _ => (AppColors.grey, estado),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        etiqueta,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.hijos});

  final String titulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(children: hijos),
        ),
      ],
    );
  }
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
      dense: true,
      leading: Icon(icono, size: 20, color: AppColors.grey),
      title: Text(
        titulo,
        style: const TextStyle(fontSize: 12, color: AppColors.grey),
      ),
      subtitle: Text(
        valor,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.black,
        ),
      ),
    );
  }
}
