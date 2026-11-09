import 'package:flutter_test/flutter_test.dart';
import 'package:novaerpmobile/models/auditoria.dart';

/// Forma real de `GET /api/core/bitacora/` (auditoria_service.serialize_evento),
/// tomada de un evento de la base de desarrollo.
const _evento = {
  'id': 165,
  'ocurrido_en': '2026-11-09T10:48:36.202883+00:00',
  'usuario_id': '49dd446c-f94e-4384-bfe7-d3cc59d848df',
  'entidad': 'sesion',
  'entidad_id': 'ab8a2fdc-984e-4817-99cc-ce69c8f18ee8',
  'operacion': 'INSERT',
  'criticidad': 'NORMAL',
  'ip_origen': '127.0.0.1',
  'valores_antes': null,
  'valores_despues': {
    'id': 'ab8a2fdc-984e-4817-99cc-ce69c8f18ee8',
    'jwt_id': '[REDACTED]',
    'tenant_id': '80501bcc-565b-43fc-a482-ca929eee6c10',
    'usuario_id': '49dd446c-f94e-4384-bfe7-d3cc59d848df',
  },
};

void main() {
  test('EventoAuditoria.fromJson lee los campos obligatorios', () {
    final e = EventoAuditoria.fromJson(Map<String, dynamic>.from(_evento));

    expect(e.id, 165);
    expect(e.ocurridoEn?.isUtc, isTrue, reason: 'la hora llega en UTC');
    expect(e.usuarioId, '49dd446c-f94e-4384-bfe7-d3cc59d848df');
    expect(e.entidad, 'sesion');
    expect(e.entidadId, 'ab8a2fdc-984e-4817-99cc-ce69c8f18ee8');
    expect(e.operacion, 'INSERT');
    expect(e.ipOrigen, '127.0.0.1');
    expect(e.valoresAntes, isNull);
    expect(e.valoresDespues, isNotNull);
    expect(e.esCambio, isTrue);
  });

  test('detecta los campos que el backend enmascaro como [REDACTED]', () {
    final e = EventoAuditoria.fromJson(Map<String, dynamic>.from(_evento));
    expect(e.camposEnmascarados, ['jwt_id']);
  });

  test('un evento sin usuario ni payload no rompe el modelo', () {
    final e = EventoAuditoria.fromJson({
      'id': 1,
      'ocurrido_en': '2026-11-09T10:00:00+00:00',
      'entidad': 'log_auditoria',
      'entidad_id': 'export',
      'operacion': 'EXPORT',
      'criticidad': 'NORMAL',
    });

    expect(e.usuarioId, isNull);
    expect(e.ipOrigen, isNull);
    expect(e.valoresDespues, isNull);
    expect(e.camposEnmascarados, isEmpty);
    expect(e.esCambio, isFalse);
  });
}
