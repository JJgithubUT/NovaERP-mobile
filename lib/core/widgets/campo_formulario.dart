import 'package:flutter/material.dart';

import '../config/app_colors.dart';

/// Campo de texto con etiqueta encima, comun a los formularios de personal
/// (alta y edicion de usuario).
///
/// [resaltado] pinta el borde cuando el backend senala este campo como la
/// causa del error (ver `ApiException.campo`).
class CampoFormulario extends StatelessWidget {
  const CampoFormulario({
    super.key,
    required this.etiqueta,
    required this.controlador,
    this.habilitado = true,
    this.tipo = TextInputType.text,
    this.resaltado = false,
    this.validador,
    this.onCambio,
  });

  final String etiqueta;
  final TextEditingController controlador;
  final bool habilitado;
  final TextInputType tipo;
  final bool resaltado;
  final String? Function(String?)? validador;

  /// Para validar "en tiempo real" mientras se captura.
  final ValueChanged<String>? onCambio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controlador,
            enabled: habilitado,
            keyboardType: tipo,
            validator: validador,
            onChanged: onCambio,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.grey.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: resaltado
                      ? AppColors.primary
                      : AppColors.grey.withValues(alpha: 0.3),
                  width: resaltado ? 1.5 : 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
