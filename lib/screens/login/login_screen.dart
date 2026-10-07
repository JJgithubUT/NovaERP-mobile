import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../providers/auth_provider.dart';

/// Fase 1 del login: correo y contrasena.
///
/// No navega: al terminar cambia el estado del AuthProvider y el AuthGate se
/// encarga de llevar al usuario al paso siguiente (codigo OTP o enrolamiento).
/// El tenant no se pide aqui; viene fijado por compilacion en ApiConstants.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    await context.read<AuthProvider>().iniciarSesion(
      _correoController.text.trim(),
      _passwordController.text,
    );
    // El resultado se refleja solo: si fue bien cambia el estado y el AuthGate
    // sustituye esta pantalla; si fue mal, el banner de error se pinta abajo.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      'lib/assets/images/logo.png',
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'Inicia sesión',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ERP móvil',
                    style: TextStyle(fontSize: 15, color: AppColors.grey),
                  ),
                  const SizedBox(height: 40),
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
                          labelText: 'Correo electrónico',
                          controller: _correoController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            final valor = v?.trim() ?? '';
                            if (valor.isEmpty) return 'Ingrese su correo';
                            if (!valor.contains('@')) return 'Correo no válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          labelText: 'Contraseña',
                          controller: _passwordController,
                          obscureText: true,
                          prefixIcon: Icons.lock_outline,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _entrar(),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Ingrese su contraseña'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: 20),
                    _BannerError(mensaje: auth.error!),
                  ],
                  const SizedBox(height: 36),
                  CustomButton(
                    text: 'Continuar',
                    isLoading: auth.cargando,
                    onPressed: _entrar,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.recuperarPassword),
                      child: const Text('¿Olvidó su contraseña?'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: AppColors.grey,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Se le pedirá un código de verificación',
                          style: TextStyle(fontSize: 12, color: AppColors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner de error compartido por las tres pantallas del flujo de acceso.
class _BannerError extends StatelessWidget {
  const _BannerError({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(fontSize: 13, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reutilizable desde otras pantallas del flujo de acceso.
class BannerErrorAuth extends StatelessWidget {
  const BannerErrorAuth({super.key, required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) => _BannerError(mensaje: mensaje);
}
