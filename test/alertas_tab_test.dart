import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novaerpmobile/screens/reports/widgets/alertas_tab.dart';

/// HU25: pestana de alertas de seguridad.
///
/// Bajo `flutter test` no hay backend: el cliente HTTP de pruebas responde 400
/// a toda peticion. Eso permite comprobar la tarjeta informativa, las pastillas,
/// que no haya ningun interruptor para desactivar los avisos y los estados de
/// error. La lista con eventos reales se verifico a mano en la app web.
void main() {
  const canal = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    // El cliente HTTP lee el token del almacen seguro; sin esta simulacion el
    // canal de la plataforma no existe en las pruebas.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null);
  });

  /// Deja que terminen las peticiones (reales, fuera del reloj falso) y pinta.
  Future<void> esperarRed(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AlertasTab())),
    );
    await esperarRed(tester);
  }

  testWidgets('explica que los avisos son automaticos y no se desactivan', (
    tester,
  ) async {
    await abrir(tester);

    expect(find.textContaining('no se pueden desactivar'), findsOneWidget);
    expect(find.text('Bloqueos de cuenta'), findsOneWidget);
    expect(find.text('Intentos fallidos'), findsOneWidget);
  });

  testWidgets('no ofrece ningun interruptor para desactivar los avisos', (
    tester,
  ) async {
    await abrir(tester);

    expect(find.byType(Switch), findsNothing);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets(
    'si falla la consulta muestra el texto del criterio y reintentar',
    (tester) async {
      await abrir(tester);

      expect(
        find.text('No fue posible consultar las alertas de seguridad.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
    },
  );

  testWidgets('cambiar de pastilla vuelve a consultar con el mismo texto', (
    tester,
  ) async {
    await abrir(tester);

    await tester.tap(find.text('Intentos fallidos'));
    await tester.pump();
    await esperarRed(tester);

    expect(
      find.text('No fue posible consultar las alertas de seguridad.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
