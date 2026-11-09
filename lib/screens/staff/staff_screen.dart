import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/permisos.dart';
import '../../core/config/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'forms/rol_form.dart';
import 'forms/usuario_form.dart';
import 'widgets/roles_tab.dart';
import 'widgets/usuarios_tab.dart';

/// Modulo de personal: directorio de usuarios (EP01) y catalogo de roles (EP02).
///
/// Las pestanas y los botones de alta salen de los permisos efectivos, no del
/// nombre del rol. Un usuario con `core:roles:leer` pero sin `core:usuarios:leer`
/// ve solo la pestana de roles, y viceversa.
///
/// Este archivo es BASE: ninguna HU necesita editarlo. Cada una vive en su
/// archivo:
///   EP01  HU05 -> forms/usuario_form.dart
///         HU06 -> widgets/usuarios_tab.dart
///         HU07 -> widgets/accion_editar_usuario.dart
///         HU08 -> widgets/accion_suspension.dart
///   EP02  HU10 -> forms/rol_form.dart
///         HU11 -> widgets/roles_tab.dart y widgets/tarjeta_rol.dart
///         HU12 -> widgets/accion_editar_rol.dart
///         HU13 -> widgets/accion_eliminar_rol.dart
class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final _usuariosKey = GlobalKey<UsuariosTabState>();
  final _rolesKey = GlobalKey<RolesTabState>();

  Future<void> _altaUsuario() async {
    if (await abrirAltaUsuario(context)) {
      _usuariosKey.currentState?.recargar();
    }
  }

  Future<void> _altaRol() async {
    if (await abrirAltaRol(context)) {
      _rolesKey.currentState?.recargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final pestanas = <_Pestana>[
      if (auth.puede(Permisos.usuariosLeer))
        _Pestana(
          etiqueta: 'Usuarios',
          icono: Icons.people_alt_outlined,
          contenido: UsuariosTab(key: _usuariosKey),
          // El alta solo tiene sentido junto al directorio: crear un usuario y
          // no poder verlo despues seria desconcertante.
          boton: auth.puede(Permisos.usuariosCrear)
              ? _Boton('Nuevo usuario', Icons.person_add_alt_1, _altaUsuario)
              : null,
        ),
      if (auth.puede(Permisos.rolesLeer))
        _Pestana(
          etiqueta: 'Roles',
          icono: Icons.badge_outlined,
          contenido: RolesTab(key: _rolesKey),
          boton: auth.puede(Permisos.rolesCrear)
              ? _Boton('Nuevo rol', Icons.add_moderator_outlined, _altaRol)
              : null,
        ),
    ];

    if (pestanas.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _barra(null),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Su rol no tiene acceso a la gestión de personal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey),
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: pestanas.length,
      child: Builder(
        builder: (contexto) {
          final controlador = DefaultTabController.of(contexto);
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: _barra(pestanas),
            body: TabBarView(children: [for (final p in pestanas) p.contenido]),
            // El boton cambia con la pestana: nuevo usuario o nuevo rol.
            floatingActionButton: AnimatedBuilder(
              animation: controlador,
              builder: (_, _) {
                final boton = pestanas[controlador.index].boton;
                if (boton == null) return const SizedBox.shrink();
                return FloatingActionButton.extended(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  onPressed: boton.alPulsar,
                  icon: Icon(boton.icono),
                  label: Text(boton.etiqueta),
                );
              },
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _barra(List<_Pestana>? pestanas) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.black,
      title: const Text(
        'Personal',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      bottom: pestanas == null || pestanas.length < 2
          ? null
          : TabBar(
              indicatorColor: AppColors.primaryLight,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.grey,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                for (final p in pestanas)
                  Tab(icon: Icon(p.icono, size: 20), text: p.etiqueta),
              ],
            ),
    );
  }
}

class _Pestana {
  const _Pestana({
    required this.etiqueta,
    required this.icono,
    required this.contenido,
    this.boton,
  });

  final String etiqueta;
  final IconData icono;
  final Widget contenido;
  final _Boton? boton;
}

class _Boton {
  const _Boton(this.etiqueta, this.icono, this.alPulsar);

  final String etiqueta;
  final IconData icono;
  final VoidCallback alPulsar;
}
