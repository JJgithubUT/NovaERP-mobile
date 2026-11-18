import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novaerpmobile/models/auditoria.dart';
import 'package:novaerpmobile/providers/auth_provider.dart';
import 'package:novaerpmobile/screens/audit/detalle_evento.dart';
import 'package:provider/provider.dart';

/// Abre el detalle de [evento] como lo hace la bitacora: empujando la ruta.
Future<void> _abrir(WidgetTester tester, EventoAuditoria evento) async {
  // Alto de sobra para que toda la pantalla quede construida sin hacer scroll.
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        home: Builder(
          builder: (contexto) => Scaffold(
            body: TextButton(
              onPressed: () => abrirDetalleEvento(contexto, evento),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

EventoAuditoria _evento({
  required String operacion,
  Map<String, dynamic>? antes,
  Map<String, dynamic>? despues,
  String entidad = 'usuario',
}) => EventoAuditoria(
  id: 1,
  entidad: entidad,
  operacion: operacion,
  criticidad: 'NORMAL',
  valoresAntes: antes,
  valoresDespues: despues,
);

void main() {
  group('UPDATE: campo que pasa a NULL', () {
    testWidgets('el valor anterior sale tachado, no como si siguiera vigente', (
      tester,
    ) async {
      const bloqueo = '2026-11-09T11:18:00+00:00';
      await _abrir(
        tester,
        _evento(
          operacion: 'UPDATE',
          antes: {'bloqueado_hasta': bloqueo, 'puesto': 'Jefe'},
          despues: {'bloqueado_hasta': null, 'puesto': 'Jefe'},
        ),
      );

      // Solo cambio bloqueado_hasta: el puesto igual no se lista.
      expect(find.text('bloqueado_hasta'), findsOneWidget);
      expect(find.text('puesto'), findsNothing);

      final viejo = tester.widget<Text>(find.text(bloqueo));
      expect(viejo.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('el valor nuevo de un campo que antes era NULL se ve normal', (
      tester,
    ) async {
      await _abrir(
        tester,
        _evento(
          operacion: 'UPDATE',
          antes: {'puesto': null},
          despues: {'puesto': 'Jefe de almacén'},
        ),
      );

      final nuevo = tester.widget<Text>(find.text('Jefe de almacén'));
      expect(nuevo.style?.decoration, isNull);
    });
  });

  group('campos que la app nunca muestra', () {
    testWidgets('el cuerpo de una notificacion queda oculto, con su token', (
      tester,
    ) async {
      await _abrir(
        tester,
        _evento(
          operacion: 'INSERT',
          entidad: 'notificacion',
          despues: {
            'asunto': 'Active su cuenta',
            'cuerpo': 'Ingrese a https://app.test/activar?token=abc123XYZ',
          },
        ),
      );

      expect(find.text('Active su cuenta'), findsOneWidget);
      expect(find.text('[OCULTO EN LA APP]'), findsOneWidget);
      expect(find.textContaining('abc123XYZ'), findsNothing);
      expect(find.textContaining('La app oculta cuerpo'), findsOneWidget);
    });

    testWidgets('tambien se oculta cuando es un cambio', (tester) async {
      await _abrir(
        tester,
        _evento(
          operacion: 'UPDATE',
          entidad: 'notificacion',
          antes: {'cuerpo': 'token=viejo111'},
          despues: {'cuerpo': 'token=nuevo222'},
        ),
      );

      expect(find.textContaining('viejo111'), findsNothing);
      expect(find.textContaining('nuevo222'), findsNothing);
      expect(find.text('[OCULTO EN LA APP]'), findsOneWidget);
    });

    testWidgets('tambien se oculta cuando es una baja', (tester) async {
      await _abrir(
        tester,
        _evento(
          operacion: 'DELETE',
          entidad: 'notificacion',
          antes: {'asunto': 'Adios', 'cuerpo': 'token=baja333'},
        ),
      );

      expect(find.text('Adios'), findsOneWidget);
      expect(find.textContaining('baja333'), findsNothing);
      expect(find.text('[OCULTO EN LA APP]'), findsOneWidget);
    });
  });
}
