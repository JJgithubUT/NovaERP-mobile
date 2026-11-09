import 'package:flutter_test/flutter_test.dart';
import 'package:novaerpmobile/models/personal.dart';

/// Forma real de `GET /api/core/roles/` (rol_service.serialize_rol): los
/// permisos llegan como LISTA de {dominio, permisos}, no como mapa.
const _rolPersonalizado = {
  'id': '11969396-8202-46d9-bfcd-8ec3607e1af1',
  'nombre': 'Sub admin',
  'es_sistema': false,
  'activo': true,
  'acceso_total': false,
  'usuarios_asignados': 1,
  'permisos': [
    {
      'dominio': 'compras',
      'permisos': [
        {
          'codigo': 'compras:config_aprobacion:editar',
          'dominio': 'compras',
          'recurso': 'config_aprobacion',
          'accion': 'editar',
          'descripcion': 'Configurar umbral de aprobacion',
          'inerte': false,
        },
        {
          'codigo': 'compras:cuentas_por_pagar:leer',
          'dominio': 'compras',
          'recurso': 'cuentas_por_pagar',
          'accion': 'leer',
          'descripcion': 'Consultar cuentas por pagar',
          'inerte': true,
        },
      ],
    },
    {
      'dominio': 'core',
      'permisos': [
        {
          'codigo': 'core:usuarios:leer',
          'dominio': 'core',
          'recurso': 'usuarios',
          'accion': 'leer',
          'descripcion': 'Consultar usuarios',
          'inerte': false,
        },
      ],
    },
  ],
};

void main() {
  test('Rol.fromJson lee los permisos agrupados por dominio del backend', () {
    final rol = Rol.fromJson(Map<String, dynamic>.from(_rolPersonalizado));

    expect(rol.nombre, 'Sub admin');
    expect(rol.usuariosAsignados, 1);
    expect(rol.permisosPorDominio.keys, containsAll(['compras', 'core']));
    expect(rol.totalPermisos, 3);
    expect(rol.permisosInertes, 1);
    expect(rol.codigosPermisos, contains('core:usuarios:leer'));
  });

  test('un rol de sistema no trae permisos y es de acceso total', () {
    final rol = Rol.fromJson({
      'id': 'a',
      'nombre': 'TENANT_ADMIN',
      'es_sistema': true,
      'activo': true,
      'acceso_total': true,
      'usuarios_asignados': 3,
      'permisos': <dynamic>[],
    });

    expect(rol.accesoTotal, isTrue);
    expect(rol.totalPermisos, 0);
  });

  test('DominioPermisos.fromJson lee el catalogo maestro', () {
    final dominios = DominioPermisos.listaDesde({
      'dominios': [
        {
          'dominio': 'core',
          'permisos': [
            {
              'codigo': 'core:roles:leer',
              'dominio': 'core',
              'recurso': 'roles',
              'accion': 'leer',
              'descripcion': 'Consultar roles',
              'inerte': false,
            },
          ],
        },
      ],
    });

    expect(dominios, hasLength(1));
    expect(dominios.single.dominio, 'core');
    expect(dominios.single.permisos.single.codigo, 'core:roles:leer');
  });
}
