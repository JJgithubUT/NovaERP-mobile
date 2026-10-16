import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart' show BannerErrorAuth;

/// Fase 2 del login: el codigo de 6 digitos del autenticador.
///
/// Aviso al usuario incluido a proposito: el backend cuenta los fallos de OTP
/// en el mismo contador que los de contrasena, asi que insistir a ciegas puede
/// bloquear la cuenta.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _codigoController = TextEditingController();
  final _focusNode = FocusNode();

  static const _longitudCodigo = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    final codigo = _codigoController.text.trim();
    if (codigo.length != _longitudCodigo) return;
    FocusScope.of(context).unfocus();

    final ok = await context.read<AuthProvider>().validarOtp(codigo);
    if (!ok && mounted) {
      // Un codigo rechazado no se reintenta tal cual: se limpia para que el
      // usuario teclee el siguiente que genere su autenticador.
      _codigoController.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: auth.cargando
              ? null
              : () => context.read<AuthProvider>().cancelarReto(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.phonelink_lock_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verificación en dos pasos',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escriba el código de 6 dígitos que muestra su aplicación '
                'de autenticación.',
                style: TextStyle(fontSize: 14, color: AppColors.grey, height: 1.4),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _codigoController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: _longitudCodigo,
                  enabled: !auth.cargando,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 12,
                    color: AppColors.black,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: '······',
                    hintStyle: TextStyle(
                      fontSize: 32,
                      letterSpacing: 12,
                      color: AppColors.grey,
                    ),
                  ),
                  onChanged: (valor) {
                    // Envio automatico al completar los 6 digitos: es lo que
                    // espera cualquiera que venga de otra app con 2FA.
                    if (valor.length == _longitudCodigo) _verificar();
                  },
                ),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 20),
                BannerErrorAuth(mensaje: auth.error!),
              ],
              const SizedBox(height: 32),
              CustomButton(
                text: 'Verificar',
                isLoading: auth.cargando,
                onPressed: _verificar,
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.grey.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Los intentos fallidos pueden bloquear la cuenta '
                      'temporalmente. El código cambia cada 30 segundos.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
