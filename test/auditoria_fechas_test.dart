import 'package:flutter_test/flutter_test.dart';
import 'package:novaerpmobile/services/auditoria_service.dart';

/// HU24 (y la consulta de la bitacora, HU21): fechas y nombre de la exportacion.
///
/// El backend trata `hasta` como EXCLUSIVO (compara contra las 00:00 de ese dia
/// en la zona horaria del servidor, `TIME_ZONE`). Para que elegir "hasta el 16"
/// incluya el 16, la app manda el 17.
void main() {
  group('hasta inclusivo (compensacion de un dia)', () {
    test('suma un dia sin importar la hora elegida', () {
      expect(
        AuditoriaService.diaSiguiente(DateTime(2026, 11, 16, 18, 45)),
        DateTime(2026, 11, 17),
      );
    });

    test('cruza el fin de mes y de anio', () {
      expect(
        AuditoriaService.diaSiguiente(DateTime(2026, 11, 30)),
        DateTime(2026, 12, 1),
      );
      expect(
        AuditoriaService.diaSiguiente(DateTime(2026, 12, 31)),
        DateTime(2027, 1, 1),
      );
    });

    test('sin fecha no inventa una', () {
      expect(AuditoriaService.diaSiguiente(null), isNull);
    });
  });

  group('nombre del archivo exportado', () {
    test('bitacora_<tenant>_<fecha>_<hora>', () {
      expect(
        AuditoriaService.nombreBase(
          DateTime.utc(2026, 11, 17, 16, 38, 5),
          tenant: 'acme',
        ),
        'bitacora_acme_20261117_163805',
      );
    });

    test('rellena con ceros las fechas de un digito', () {
      expect(
        AuditoriaService.nombreBase(
          DateTime.utc(2026, 1, 2, 3, 4, 5),
          tenant: 'x',
        ),
        'bitacora_x_20260102_030405',
      );
    });
  });
}
