import 'package:flutter_test/flutter_test.dart';
import 'package:novaerpmobile/models/reportes.dart';

/// Forma real de `GET /api/core/reportes/actividad/`
/// (auditoria_service._serialize_actividad).
const _fila = {
  'usuario_id': 'c22b0d9f-3432-429e-8139-979cdff4c21a',
  'nombre_completo': 'Tests Usuario',
  'correo': 'juanjcbreton@outlook.com',
  'departamento': 'Admins',
  'puesto': 'Admin',
  'estado': 'activo',
  'ultimo_acceso': '2026-11-09T10:48:36.202883+00:00',
  'num_sesiones': 4,
  'num_acciones_cud': 12,
};

void main() {
  test('ActividadUsuario.fromJson lee los campos del reporte', () {
    final a = ActividadUsuario.fromJson(Map<String, dynamic>.from(_fila));

    expect(a.nombreCompleto, 'Tests Usuario');
    expect(a.departamento, 'Admins');
    expect(a.puesto, 'Admin');
    expect(a.estado, 'activo');
    expect(a.ultimoAcceso?.isUtc, isTrue);
    expect(a.numSesiones, 4);
    expect(a.numAccionesCud, 12);
    expect(a.sinAcceso, isFalse);
    expect(a.sinActividad, isFalse);
  });

  test('un usuario que nunca entro y sin acciones es candidato a inactivo', () {
    final a = ActividadUsuario.fromJson({
      'usuario_id': 'u1',
      'nombre_completo': 'Pendiente',
      'correo': 'p@acme.com',
      'departamento': null,
      'puesto': null,
      'estado': 'pendiente',
      'ultimo_acceso': null,
      'num_sesiones': 0,
      'num_acciones_cud': 0,
    });

    expect(a.sinAcceso, isTrue);
    expect(a.sinActividad, isTrue);
    expect(a.departamento, isNull);
  });
}
