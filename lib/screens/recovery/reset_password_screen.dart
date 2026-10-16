import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../services/auth_service.dart';
import '../login/login_screen.dart' show BannerErrorAuth;

/// HU18 - Paso 2: token del correo + nueva contrasena.
///
/// La app no tiene enlaces profundos, asi que el usuario pega aqui el token
/// que recibio por correo. El token es de un solo uso y vence en 1 hora; si
/// esta vencido o ya se uso, el backend responde igual en ambos casos.
/// Al restablecer, el backend invalida todas las sesiones previas.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarController = TextEditingController();
  final _authService = AuthService();

  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _restablecer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await _authService.restablecerPassword(
        _tokenController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      // Vuelve al login (raiz). El login sigue siendo lo que muestra AuthGate.
      Navigator.of(context).popUntil((ruta) => ruta.isFirst);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Contraseña restablecida. Inicie sesión de nuevo.'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.mensaje;
      });
    }
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
                  'Nueva contraseña',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pegue el código que recibió por correo y elija una nueva '
                  'contraseña. Al cambiarla se cerrarán todas sus sesiones.',
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
                  child: Column(
                    children: [
                      CustomTextField(
                        labelText: 'Código de recuperación',
                        controller: _tokenController,
                        prefixIcon: Icons.vpn_key_outlined,
                        enabled: !_cargando,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Ingrese el código recibido'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        labelText: 'Nueva contraseña',
                        controller: _passwordController,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                        enabled: !_cargando,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Ingrese la nueva contraseña'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        labelText: 'Confirmar contraseña',
                        controller: _confirmarController,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                        enabled: !_cargando,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _restablecer(),
                        validator: (v) => v != _passwordController.text
                            ? 'Las contraseñas no coinciden'
                            : null,
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 20),
                  BannerErrorAuth(mensaje: _error!),
                ],
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Restablecer contraseña',
                  isLoading: _cargando,
                  onPressed: _restablecer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
