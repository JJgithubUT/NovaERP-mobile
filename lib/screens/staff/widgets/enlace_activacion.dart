import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/api_constants.dart';
import '../../../core/config/app_colors.dart';

/// Entrega del enlace de activacion de un usuario recien creado.
///
/// El backend no envia correos todavia (el worker de RF-25 no existe), asi que
/// el token viaja en la respuesta del alta y es responsabilidad de quien la
/// hizo hacerselo llegar a la persona. Ademas el token NO se guarda en claro:
/// esta pantalla es la unica oportunidad de copiarlo.
///
/// De ahi que no se pueda cerrar con el boton de atras ni tocando fuera: salir
/// sin copiarlo obliga a reemitir el enlace.
Future<void> mostrarEnlaceActivacion(
  BuildContext context, {
  required String nombreUsuario,
  required String correo,
  required String token,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DialogoEnlace(
      nombreUsuario: nombreUsuario,
      correo: correo,
      token: token,
    ),
  );
}

class _DialogoEnlace extends StatelessWidget {
  const _DialogoEnlace({
    required this.nombreUsuario,
    required this.correo,
    required this.token,
  });

  final String nombreUsuario;
  final String correo;
  final String token;

  /// Lo que se comparte: la URL completa si hay base configurada, o el token
  /// solo si no la hay.
  String get _contenido => ApiConstants.enlaceActivacion(token) ?? token;

  bool get _hayEnlace => ApiConstants.enlaceActivacion(token) != null;

  String get _mensajeCompartir =>
      'Hola $nombreUsuario, active su cuenta de NovaERP con este '
      '${_hayEnlace ? 'enlace' : 'código'}:\n\n$_contenido\n\n'
      'Caduca en 24 horas y solo puede usarse una vez.';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Salir sin copiar el token lo pierde para siempre.
      canPop: false,
      child: AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_alt_1,
                color: AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Usuario creado', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$nombreUsuario ($correo) debe activar su cuenta para poder '
                'entrar. Hágale llegar esto:',
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: SelectableText(
                  _contenido,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontFamily: 'monospace',
                    color: AppColors.black,
                    height: 1.4,
                  ),
                ),
              ),

              if (!_hayEnlace) ...[
                const SizedBox(height: 12),
                _Aviso(
                  icono: Icons.info_outline,
                  color: AppColors.grey,
                  texto:
                      'Se muestra solo el código porque no hay una URL de '
                      'activación configurada. Compílela con '
                      '--dart-define=ACTIVACION_URL_BASE=… para compartir un '
                      'enlace en el que se pueda pulsar.',
                ),
              ],

              const SizedBox(height: 12),
              const _Aviso(
                icono: Icons.warning_amber_rounded,
                color: AppColors.warning,
                texto:
                    'Caduca en 24 horas, sirve una sola vez y no se puede '
                    'volver a consultar. Si lo pierde, tendrá que reemitirlo.',
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _contenido));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text(
                    _hayEnlace ? 'Enlace copiado' : 'Código copiado',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copiar'),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () => Share.share(
                  _mensajeCompartir,
                  subject: 'Active su cuenta de NovaERP',
                ),
                icon: const Icon(Icons.ios_share, size: 18),
                label: const Text('Compartir'),
              ),
              const SizedBox(width: 4),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Listo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icono,
    required this.color,
    required this.texto,
  });

  final IconData icono;
  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.black,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
