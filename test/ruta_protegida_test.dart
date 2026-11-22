import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novaerpmobile/core/routes/ruta_protegida.dart';
import 'package:novaerpmobile/providers/auth_provider.dart';
import 'package:novaerpmobile/screens/splash/splash_screen.dart';
import 'package:provider/provider.dart';

/// App minima con la misma forma que la real: '/' hace de AuthGate y
/// '/protegida' se abre "tecleando la URL" (initialRoute apila '/' debajo).
Widget _app(AuthProvider auth) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: MaterialApp(
      initialRoute: '/protegida',
      routes: {
        '/': (_) => const Scaffold(body: Text('login')),
        '/protegida': (_) =>
            const RutaProtegida(child: Scaffold(body: Text('datos privados'))),
      },
    ),
  );
}

void main() {
  testWidgets('mientras se comprueba la sesion no muestra la pantalla', (
    tester,
  ) async {
    final auth = AuthProvider();
    expect(auth.estado, EstadoSesion.comprobando);

    await tester.pumpWidget(_app(auth));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('datos privados'), findsNothing);
  });

  testWidgets('sin sesion retira la ruta y deja ver el login', (tester) async {
    final auth = AuthProvider();
    await tester.pumpWidget(_app(auth));

    // Pasa a sinSesion sin tocar red ni almacenamiento.
    auth.cancelarReto();
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(find.text('datos privados'), findsNothing);
    expect(find.byType(RutaProtegida), findsNothing);
  });
}
