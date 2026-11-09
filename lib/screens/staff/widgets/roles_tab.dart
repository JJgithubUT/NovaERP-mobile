import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';

/// HU11 - Visualizar roles y permisos asignados.
///
/// Guia: usar `ListaPaginada<Rol>` (core/widgets) con `PersonalService.roles`
/// y pintar cada rol con `TarjetaRol` (widgets/tarjeta_rol.dart), pasandole
/// `onCambio: recargar` para que la lista se actualice tras editar, desactivar
/// o reactivar un rol. Error de consulta: "No fue posible recuperar el listado
/// de roles."
///
/// Contrato que usa StaffScreen: la clase `RolesTab` con su estado publico
/// `RolesTabState` y el metodo [recargar]. Conservar esos nombres.
class RolesTab extends StatefulWidget {
  const RolesTab({super.key});

  @override
  State<RolesTab> createState() => RolesTabState();
}

class RolesTabState extends State<RolesTab> {
  /// Vuelve a pedir la primera pagina (la llama StaffScreen tras crear un rol).
  void recargar() {
    // TODO(HU11): recargar la lista paginada.
  }

  @override
  Widget build(BuildContext context) {
    // TODO(HU11): reemplazar este marcador por la lista de roles.
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'HU11: listado de roles pendiente.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.grey),
        ),
      ),
    );
  }
}
