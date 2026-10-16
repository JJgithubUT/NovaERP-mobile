import 'package:flutter/material.dart';

/// Pantalla de arranque. Puramente visual: se muestra mientras AuthGate
/// comprueba si hay una sesion guardada que el backend siga aceptando. La
/// navegacion la decide el estado de la sesion, no un temporizador.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'NovaERP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Color(0xFF9E1A22)),
          ],
        ),
      ),
    );
  }
}
