import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
