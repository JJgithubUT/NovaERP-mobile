import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';

/// HU10 - Crear rol de trabajo. Devuelve true si se creo.
///
/// Guia: formulario con el nombre (`CampoFormulario`, core/widgets) y el
/// selector `SelectorPermisos` (core/widgets), que se alimenta de
/// `PersonalService.catalogoPermisos()`. Guardar con
/// `PersonalService.crearRol` y cerrar con `Navigator.pop(true)`.
///
/// Criterios: bloquear el guardado si el nombre ya existe en la empresa (lo
/// rechaza el backend con 422, campo 'nombre') y si no hay al menos un permiso
/// (campo 'permisos'). Error general: "No fue posible crear el rol. Verifique
/// los datos e intente nuevamente."
///
/// Contrato que usa StaffScreen: la funcion `abrirAltaRol`. Conservar el
/// nombre y la firma.
Future<bool> abrirAltaRol(BuildContext context) async {
  final creado = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const _FormularioRol(),
    ),
  );
  return creado ?? false;
}

class _FormularioRol extends StatelessWidget {
  const _FormularioRol();

  @override
  Widget build(BuildContext context) {
    // TODO(HU10): reemplazar este marcador por el formulario.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Nuevo rol',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: const Center(
        child: Text(
          'HU10: alta de rol pendiente.',
          style: TextStyle(color: AppColors.grey),
        ),
      ),
    );
  }
}
