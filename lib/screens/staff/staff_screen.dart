import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/permisos.dart';
import '../../core/config/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'forms/usuario_form.dart';
import 'widgets/usuarios_tab.dart';

/// Modulo de personal (EP01): directorio de usuarios y alta.
///
/// La pantalla y el boton de alta salen de los permisos efectivos, no del nombre
/// del rol. La gestion de roles (EP02) se agregara como otra pestana.
///
/// Este archivo es BASE: ninguna HU de EP01 necesita editarlo. Cada una vive en
/// su archivo:
///   HU05 -> forms/usuario_form.dart
///   HU06 -> widgets/usuarios_tab.dart
///   HU07 -> widgets/accion_editar_usuario.dart
///   HU08 -> widgets/accion_suspension.dart
class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final _usuariosKey = GlobalKey<UsuariosTabState>();

  Future<void> _altaUsuario() async {
    if (await abrirAltaUsuario(context)) {
      _usuariosKey.currentState?.recargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final puedeVerUsuarios = auth.puede(Permisos.usuariosLeer);

    // El alta solo tiene sentido junto al directorio: crear un usuario y no
    // poder verlo despues seria desconcertante.
    final puedeDarDeAlta = auth.puede(Permisos.usuariosCrear) && puedeVerUsuarios;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
      ),
      body: puedeVerUsuarios
          ? UsuariosTab(key: _usuariosKey)
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Su rol no tiene acceso a la gestión de personal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey),
                ),
              ),
            ),
      floatingActionButton: puedeDarDeAlta
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: _altaUsuario,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Nuevo usuario'),
            )
          : null,
    );
  }
}
