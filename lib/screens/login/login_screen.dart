import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- CREDENCIALES PRECARGADAS PARA DESARROLLO ---
  final _emailController = TextEditingController(
    text: 'ortizyarezti@gmail.com',
  );
  final _passwordController = TextEditingController(text: '123456');

  // --- PALETA DE COLORES REQUERIDA ---
  final Color guindaBase = const Color(0xFF73030D);
  final Color rojoVivo = const Color(0xFF9E1A22);
  final Color fondoPrincipal = const Color(0xFFF2F2F2);
  final Color negroProfundo = const Color(0xFF0D0D0D);
  final Color grisMedio = const Color(0xFFAFAFAF);

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 1. FORZAR INICIO DE SESIÓN LOCAL CON ESTAS CREDENCIALES
    if (email == 'ortizyarezti@gmail.com' && password == '123456') {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
      return; // Detiene la ejecución aquí para no evaluar la API externa
    }

    // 2. RESPALDO: Intento de autenticación normal por si ingresas otros datos
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(email, password);

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: guindaBase,
          content: const Text(
            'Error de autenticación. Verifica tus datos.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoPrincipal,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CABECERA DE MARCA MINIMALISTA CON LOGO DIRECTO ---
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 48),

                Text(
                  "Inicia sesión",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: negroProfundo,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "ERP móvil",
                  style: TextStyle(fontSize: 15, color: grisMedio),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: grisMedio.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      CustomTextField(
                        labelText: 'Correo Electrónico',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        labelText: 'Contraseña',
                        controller: _passwordController,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // --- ACCIÓN DE INICIO DE SESIÓN ---
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return CustomButton(
                      text: 'Iniciar Sesión',
                      isLoading: auth.isLoading,
                      onPressed: _handleLogin,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
