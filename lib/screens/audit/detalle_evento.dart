import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';
import '../../models/auditoria.dart';

/// HU20 - Detalle de un evento de la bitacora.
///
/// El registro automatico lo hace el backend (append-only, con los datos
/// sensibles enmascarados como `[REDACTED]`); la app lo muestra. Guia: pantalla
/// de solo lectura con los 7 campos obligatorios del registro: marca de tiempo
/// (UTC), tenant, usuario, IP de origen, tipo de operacion, id de la entidad
/// afectada y el payload diferencial (`valoresAntes` / `valoresDespues`),
/// resaltando los campos enmascarados (`camposEnmascarados`). Sin acciones de
/// edicion ni de baja.
///
/// Contrato que usa BitacoraTab (HU21): la funcion `abrirDetalleEvento`.
/// [nombreUsuario] es el nombre resuelto del usuario, si se pudo obtener.
Future<void> abrirDetalleEvento(
  BuildContext context,
  EventoAuditoria evento, {
  String? nombreUsuario,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) =>
          _DetalleEvento(evento: evento, nombreUsuario: nombreUsuario),
    ),
  );
}

class _DetalleEvento extends StatelessWidget {
  const _DetalleEvento({required this.evento, this.nombreUsuario});

  final EventoAuditoria evento;
  final String? nombreUsuario;

  @override
  Widget build(BuildContext context) {
    // TODO(HU20): reemplazar este marcador por el detalle.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Detalle del evento',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: const Center(
        child: Text(
          'HU20: detalle de evento pendiente.',
          style: TextStyle(color: AppColors.grey),
        ),
      ),
    );
  }
}
