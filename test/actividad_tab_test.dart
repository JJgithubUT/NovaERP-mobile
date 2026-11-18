import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novaerpmobile/screens/reports/widgets/actividad_tab.dart';

/// HU23: pestana de actividad.
///
/// Bajo `flutter test` no hay backend: el cliente HTTP de pruebas responde 400
/// a toda peticion. Eso permite comprobar los estados de error (catalogo de
/// filtros y lista) y que la pestana conserve su estado al cambiar de pestana.
void main() {
  setUp(() {
    // El cliente HTTP lee el token del almacen seguro; sin esta simulacion el
    // canal de la plataforma no existe en las pruebas.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          null,
        );
  });

  /// Deja que terminen las peticiones (reales, fuera del reloj falso) y pinta.
  Future<void> esperarRed(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('si falla la lista muestra el texto del criterio y reintentar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ActividadTab())),
    );
    await esperarRed(tester);

    expect(
      find.text('No fue posible generar el reporte de actividad.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
    // Los filtros no dependen de la lista: siguen disponibles.
    expect(find.text('Filtros'), findsOneWidget);
    expect(find.text('7 días'), findsOneWidget);
  });

  testWidgets('si falla el catalogo, la hoja avisa y ofrece reintentar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ActividadTab())),
    );
    await esperarRed(tester);

    await tester.tap(find.text('Filtros'));
    await tester.pump(const Duration(milliseconds: 400));

    final hoja = find.byType(BottomSheet);
    expect(
      find.descendant(
        of: hoja,
        matching: find.text(
          'No se pudieron cargar los departamentos y puestos.',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: hoja, matching: find.text('Reintentar')),
      findsOneWidget,
    );
    // No es lo mismo "fallo" que "no hay datos".
    expect(
      find.text('Sin datos de departamento ni puesto para filtrar.'),
      findsNothing,
    );
  });

  testWidgets('la pestana conserva sus filtros al cambiar de pestana', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'A'),
                  Tab(text: 'B'),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                ActividadTab(),
                Center(child: Text('otra pestana')),
              ],
            ),
          ),
        ),
      ),
    );
    await esperarRed(tester);

    // Sin filtros no hay boton "Limpiar".
    expect(find.text('Limpiar'), findsNothing);
    await tester.tap(find.text('7 días'));
    await tester.pump();
    await esperarRed(tester);
    expect(find.text('Limpiar'), findsOneWidget);

    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    expect(find.text('otra pestana'), findsOneWidget);

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    expect(
      find.text('Limpiar'),
      findsOneWidget,
      reason: 'el filtro de 7 dias sigue aplicado al volver',
    );
  });

  testWidgets('el Reintentar de una hoja que sobrevive a la pestana no revienta', (
    tester,
  ) async {
    final mostrar = ValueNotifier<bool>(true);
    addTearDown(mostrar.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: mostrar,
            builder: (_, visible, _) =>
                visible ? const ActividadTab() : const SizedBox(),
          ),
        ),
      ),
    );
    await esperarRed(tester);

    await tester.tap(find.text('Filtros'));
    // Que la hoja termine de subir: si no, el boton queda fuera de la pantalla y
    // el toque no lo alcanza.
    await tester.pumpAndSettle();
    final reintentar = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text('Reintentar'),
    );
    expect(reintentar, findsOneWidget);

    // La pestana se desmonta (por ejemplo, al cerrar sesion) y la hoja, que es
    // una ruta aparte, sigue abierta encima.
    mostrar.value = false;
    await tester.pumpAndSettle();
    expect(find.byType(ActividadTab), findsNothing);
    expect(reintentar, findsOneWidget);

    await tester.tap(reintentar);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
