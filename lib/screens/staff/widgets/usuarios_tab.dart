import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';

/// HU06 - Consultar directorio de usuarios.
///
/// Guia: usar `ListaPaginada<UsuarioDirectorio>` (core/widgets) con
/// `PersonalService.usuarios`, y abrir la ficha con `abrirDetalleUsuario`
/// (screens/staff/detalle_usuario.dart); si devuelve true, llamar [recargar].
///
/// Contrato que usa StaffScreen: la clase `UsuariosTab` con su estado publico
/// `UsuariosTabState` y el metodo [recargar]. Conservar esos nombres.
class UsuariosTab extends StatefulWidget {
  const UsuariosTab({super.key});

  @override
  State<UsuariosTab> createState() => UsuariosTabState();
}

class UsuariosTabState extends State<UsuariosTab> {
  /// Vuelve a pedir la primera pagina (la llama StaffScreen tras un alta).
  void recargar() {
    // TODO(HU06): recargar la lista paginada.
  }

  @override
  Widget build(BuildContext context) {
    // TODO(HU06): reemplazar este marcador por el directorio.
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'HU06: directorio de usuarios pendiente.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.grey),
        ),
      ),
    );
  }
}
