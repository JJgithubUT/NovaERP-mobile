import 'package:flutter/material.dart';

import '../config/app_colors.dart';

/// Fila de accion de una ficha (icono, titulo y detalle). La usan las acciones
/// administrativas sobre un usuario (editar, suspender...).
///
/// [peligrosa] la pinta con el color de aviso (acciones que bloquean acceso).
class AccionTile extends StatelessWidget {
  const AccionTile({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.detalle,
    required this.onTap,
    this.deshabilitado = false,
    this.peligrosa = false,
  });

  final IconData icono;
  final String etiqueta;
  final String detalle;
  final VoidCallback onTap;
  final bool deshabilitado;
  final bool peligrosa;

  @override
  Widget build(BuildContext context) {
    final color = deshabilitado
        ? AppColors.grey
        : (peligrosa ? AppColors.primaryLight : AppColors.primary);

    return ListTile(
      enabled: !deshabilitado,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icono, size: 20, color: color),
      ),
      title: Text(
        etiqueta,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: deshabilitado ? AppColors.grey : AppColors.black,
        ),
      ),
      subtitle: Text(detalle, style: const TextStyle(fontSize: 12)),
      onTap: deshabilitado ? null : onTap,
    );
  }
}
