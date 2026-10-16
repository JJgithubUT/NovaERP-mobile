import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../services/auth_service.dart';
import '../login/login_screen.dart' show BannerErrorAuth;
import 'reset_password_screen.dart';

/// HU18 - Paso 1: solicitar el correo de recuperacion.
///
/// Es una pantalla publica (no hay sesion). El backend responde lo mismo exista
/// o no la cuenta, asi que el mensaje de exito tambien es siempre el mismo: no
/// se debe revelar que correos estan dados de alta.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _authService = AuthService();

  bool _cargando = false;
  bool _enviado = false;
  String? _error;

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await _authService.recuperarPassword(_correoController.text.trim());
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _enviado = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.mensaje;
      });
    }
  }

  void _irARestablecer() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recuperar contraseña',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Escriba el correo de su cuenta. Si existe, le enviaremos '
                  'las instrucciones para restablecer su contraseña.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: CustomTextField(
                    labelText: 'Correo electrónico',
                    controller: _correoController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    enabled: !_cargando,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _enviar(),
                    validator: (v) {
                      final valor = v?.trim() ?? '';
                      if (valor.isEmpty) return 'Ingrese su correo';
                      if (!valor.contains('@')) return 'Correo no válido';
                      return null;
                    },
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 20),
                  BannerErrorAuth(mensaje: _error!),
                ],
                if (_enviado) ...[
                  const SizedBox(height: 20),
                  const _AvisoEnviado(),
                ],
                const SizedBox(height: 32),
                CustomButton(
                  text: _enviado ? 'Reenviar correo' : 'Enviar instrucciones',
                  isLoading: _cargando,
                  onPressed: _enviar,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _irARestablecer,
                    child: const Text('Ya tengo mi código de recuperación'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvisoEnviado extends StatelessWidget {
  const _AvisoEnviado();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mark_email_read_outlined, size: 18, color: AppColors.success),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Si el correo existe en el sistema, recibirá instrucciones. '
              'El enlace es de un solo uso y vence en 1 hora.',
              style: TextStyle(fontSize: 13, color: AppColors.black),
            ),
          ),
        ],
      ),
    );
  }
}
