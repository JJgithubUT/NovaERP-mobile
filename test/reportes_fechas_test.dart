import 'package:flutter_test/flutter_test.dart';
import 'package:novaerpmobile/screens/reports/widgets/filtro_fechas.dart';
import 'package:novaerpmobile/services/reportes_service.dart';

/// HU23: fechas del reporte de actividad.
///
/// El backend trata `hasta` como EXCLUSIVO (compara contra las 00:00 de ese dia
/// en la zona horaria del servidor, `TIME_ZONE`). Para que elegir "hasta el 16"
/// incluya el 16, la app manda el 17.
void main() {
  group('hasta inclusivo (compensacion de un dia)', () {
    test('suma un dia sin importar la hora elegida', () {
      expect(
        ReportesService.diaSiguiente(DateTime(2026, 11, 16, 18, 45)),
        DateTime(2026, 11, 17),
      );
    });

    test('cruza el fin de mes y de anio', () {
      expect(
        ReportesService.diaSiguiente(DateTime(2026, 11, 30)),
        DateTime(2026, 12, 1),
      );
      expect(
        ReportesService.diaSiguiente(DateTime(2026, 12, 31)),
        DateTime(2027, 1, 1),
      );
    });

    test('sin fecha no inventa una', () {
      expect(ReportesService.diaSiguiente(null), isNull);
    });
  });

  group('nombre del archivo exportado', () {
    test('actividad_<tenant>_<fecha>_<hora>', () {
      expect(
        ReportesService.nombreBase(
          DateTime.utc(2026, 11, 17, 16, 38, 5),
          tenant: 'acme',
        ),
        'actividad_acme_20261117_163805',
      );
    });

    test('rellena con ceros las fechas de un digito', () {
      expect(
        ReportesService.nombreBase(
          DateTime.utc(2026, 1, 2, 3, 4, 5),
          tenant: 'x',
        ),
        'actividad_x_20260102_030405',
      );
    });
  });

  group('atajos del selector de fechas', () {
    test('"Hoy" empieza el mismo dia, sin importar la hora', () {
      expect(
        FiltroFechas.inicioUltimosDias(DateTime(2026, 11, 17, 15, 30), 1),
        DateTime(2026, 11, 17),
      );
    });

    test('"7 dias" incluye hoy: empieza 6 dias antes', () {
      expect(
        FiltroFechas.inicioUltimosDias(DateTime(2026, 11, 17), 7),
        DateTime(2026, 11, 11),
      );
    });

    test('"30 dias" cruza el fin de mes', () {
      expect(
        FiltroFechas.inicioUltimosDias(DateTime(2026, 11, 17), 30),
        DateTime(2026, 10, 19),
      );
    });

    test(
      'es aritmetica de calendario: cruzar un cambio de hora no corre el dia',
      () {
        // Con Duration(days: 29) esta cuenta caia el 11/03 a las 23:00 en una zona
        // con horario de verano (y el reporte contaba un dia de mas).
        final inicio = FiltroFechas.inicioUltimosDias(
          DateTime(2027, 4, 10),
          30,
        );
        expect(inicio, DateTime(2027, 3, 12));
        expect(inicio.hour, 0);
      },
    );
  });
}
