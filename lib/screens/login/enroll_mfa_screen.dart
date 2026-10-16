import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/config/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/auth_provider.dart';

/// Enrolamiento del segundo factor (primer acceso, o tras un reset de MFA).
///
/// El backend entrega el secreto y el otpauth_uri UNA SOLA VEZ, junto con el
/// reto de la fase 1. Si el usuario sale de aqui sin guardarlo, necesitara que
/// un administrador le resetee el MFA: de ahi el aviso y que no haya forma de
/// avanzar sin confirmar explicitamente.
class EnrollMfaScreen extends StatelessWidget {
  const EnrollMfaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final reto = auth.reto;

    // Defensa por si se llega aqui sin reto (por ejemplo, tras un hot reload).
    if (reto == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final secreto = reto.secreto ?? '';
    final uri = reto.otpauthUri ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.read<AuthProvider>().cancelarReto(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure su segundo factor',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escanee el código con Google Authenticator, Microsoft '
                'Authenticator o similar. Si abre esta app en el mismo '
                'teléfono, copie la clave y péguela en su autenticador.',
                style: TextStyle(fontSize: 14, color: AppColors.grey, height: 1.4),
              ),
              const SizedBox(height: 24),

              if (uri.isNotEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    // Fondo blanco fijo y sin color de marca: un QR con poco
                    // contraste o teñido no siempre lo lee la camara.
                    child: QrImageView(
                      data: uri,
                      size: 220,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              const Text(
                'Clave de configuración',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              _ClaveCopiable(secreto: secreto),

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Esta clave se muestra una sola vez. Si la pierde, un '
                        'administrador tendrá que restablecer su segundo factor.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.black,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              CustomButton(
                text: 'Ya lo guardé, continuar',
                onPressed: () =>
                    context.read<AuthProvider>().confirmarEnrolamiento(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClaveCopiable extends StatelessWidget {
  const _ClaveCopiable({required this.secreto});

  final String secreto;

  /// El secreto base32 se lee mucho mejor partido en grupos de cuatro.
  String get _agrupado {
    final buffer = StringBuffer();
    for (var i = 0; i < secreto.length; i += 4) {
      if (i > 0) buffer.write(' ');
      buffer.write(secreto.substring(i, (i + 4).clamp(0, secreto.length)));
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              _agrupado,
              style: const TextStyle(
                fontSize: 15,
                fontFamily: 'monospace',
                letterSpacing: 1.1,
                color: AppColors.black,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
            tooltip: 'Copiar clave',
            onPressed: () async {
              // Se copia sin espacios: los autenticadores no los aceptan.
              await Clipboard.setData(ClipboardData(text: secreto));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text(
                    'Clave copiada al portapapeles',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
