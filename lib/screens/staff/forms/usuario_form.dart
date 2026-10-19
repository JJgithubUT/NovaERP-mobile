import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';

/// HU05 - Alta de usuario. Devuelve true si se creo.
///
/// Guia: formulario con `CampoFormulario` (core/widgets), selector de roles con
/// `PersonalService.rolesActivos`, alta con `PersonalService.crearUsuario` y, al
/// terminar, `mostrarEnlaceActivacion` (widgets/enlace_activacion.dart), que es
/// la unica vez que el backend entrega el token en claro. Cerrar con
/// `Navigator.pop(true)`.
///
/// Contrato que usa StaffScreen: la funcion `abrirAltaUsuario`. Conservar el
/// nombre y la firma.
Future<bool> abrirAltaUsuario(BuildContext context) async {
  final creado = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const _FormularioUsuario(),
    ),
  );
  return creado ?? false;
}

class _FormularioUsuario extends StatelessWidget {
  const _FormularioUsuario();

  @override
  Widget build(BuildContext context) {
    // TODO(HU05): reemplazar este marcador por el formulario.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Nuevo usuario',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: const Center(
        child: Text(
          'HU05: alta de usuario pendiente.',
          style: TextStyle(color: AppColors.grey),
        ),
      ),
    );
  }
}
