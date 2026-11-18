import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novaerpmobile/core/network/api_exception.dart';
import 'package:novaerpmobile/core/widgets/lista_paginada.dart';
import 'package:novaerpmobile/models/paginado.dart';

Paginado<String> _pagina(List<String> elementos) => Paginado(
  total: elementos.length,
  pagina: 1,
  tamanoPagina: 20,
  numeroPaginas: 1,
  elementos: elementos,
);

void main() {
  testWidgets('recargar durante una carga descarta la respuesta vieja', (
    tester,
  ) async {
    final pendientes = <Completer<Paginado<String>>>[];
    final llave = GlobalKey<ListaPaginadaState<String>>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListaPaginada<String>(
            key: llave,
            cargar: (_) {
              final c = Completer<Paginado<String>>();
              pendientes.add(c);
              return c.future;
            },
            itemBuilder: (_, e) => Text(e),
          ),
        ),
      ),
    );
    expect(pendientes, hasLength(1)); // primera consulta en vuelo

    // El usuario cambia la busqueda antes de que responda la primera.
    llave.currentState!.recargar();
    await tester.pump();
    expect(pendientes, hasLength(2), reason: 'la recarga debe pedir de nuevo');

    // La consulta nueva responde primero; la vieja llega tarde.
    pendientes[1].complete(_pagina(['nuevo']));
    await tester.pump();
    pendientes[0].complete(_pagina(['viejo']));
    await tester.pump();

    expect(find.text('nuevo'), findsOneWidget);
    expect(find.text('viejo'), findsNothing);
  });

  testWidgets('recargar vuelve a pedir la primera pagina', (tester) async {
    var llamadas = 0;
    final llave = GlobalKey<ListaPaginadaState<String>>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListaPaginada<String>(
            key: llave,
            cargar: (pagina) async {
              llamadas++;
              return _pagina(['fila $llamadas']);
            },
            itemBuilder: (_, e) => Text(e),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('fila 1'), findsOneWidget);

    await llave.currentState!.recargar();
    await tester.pumpAndSettle();

    expect(find.text('fila 2'), findsOneWidget);
    expect(find.text('fila 1'), findsNothing);
  });

  testWidgets('actualizar reemplaza los datos sin vaciar la lista', (
    tester,
  ) async {
    var version = 1;
    final pendiente = <Completer<Paginado<String>>>[];
    final llave = GlobalKey<ListaPaginadaState<String>>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListaPaginada<String>(
            key: llave,
            cargar: (_) {
              if (version == 1) return Future.value(_pagina(['viejo']));
              final c = Completer<Paginado<String>>();
              pendiente.add(c);
              return c.future;
            },
            itemBuilder: (_, e) => Text(e),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('viejo'), findsOneWidget);

    version = 2;
    final futuro = llave.currentState!.actualizar();
    await tester.pump();

    // Mientras llegan los datos nuevos, lo anterior sigue visible y no hay
    // indicador de carga a pantalla completa.
    expect(find.text('viejo'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    pendiente.single.complete(_pagina(['nuevo']));
    await futuro;
    await tester.pump();
    expect(find.text('nuevo'), findsOneWidget);
    expect(find.text('viejo'), findsNothing);
  });

  group('fallo al pedir una pagina posterior', () {
    // Pagina 1 con filas altas para que haya scroll y se pida la 2.
    Paginado<String> primera() => Paginado(
      total: 40,
      pagina: 1,
      tamanoPagina: 20,
      numeroPaginas: 2,
      elementos: [for (var i = 0; i < 20; i++) 'fila $i'],
    );

    Future<void> llegarAlFinal(
      WidgetTester tester,
      ApiException error, {
      String? mensajeError,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListaPaginada<String>(
              mensajeError: mensajeError,
              cargar: (pagina) async {
                if (pagina == 1) return primera();
                throw error;
              },
              itemBuilder: (_, e) => ListTile(title: Text(e)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pumpAndSettle();
    }

    const caida = ApiException(
      mensaje:
          'No se pudo establecer la conexion.\n\nDestino: http://x/?page=2',
    );

    testWidgets('muestra el texto fijo del criterio, sin la URL tecnica', (
      tester,
    ) async {
      await llegarAlFinal(
        tester,
        caida,
        mensajeError: 'No fue posible generar el reporte.',
      );

      expect(find.text('No fue posible generar el reporte.'), findsOneWidget);
      expect(find.textContaining('Destino'), findsNothing);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('sin texto fijo conserva el mensaje del servidor', (
      tester,
    ) async {
      await llegarAlFinal(tester, caida);

      expect(find.textContaining('Destino'), findsOneWidget);
    });

    testWidgets(
      'el 403 conserva el detalle del permiso aunque haya texto fijo',
      (tester) async {
        await llegarAlFinal(
          tester,
          const ApiException(
            statusCode: 403,
            mensaje: 'Falta el permiso core:reportes:leer.',
          ),
          mensajeError: 'No fue posible generar el reporte.',
        );

        expect(
          find.text('Falta el permiso core:reportes:leer.'),
          findsOneWidget,
        );
        expect(find.text('No fue posible generar el reporte.'), findsNothing);
      },
    );
  });
}
