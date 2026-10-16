import 'package:flutter_test/flutter_test.dart';
import 'package:novaerpmobile/core/auth/permisos.dart';
import 'package:novaerpmobile/models/usuario.dart';

/// Contexto de prueba con un conjunto de permisos dado.
ContextoSesion _contextoCon(
  List<String> permisos, {
  bool esAdmin = false,
}) {
  return ContextoSesion.fromJson({
    'usuario': {
      'id': 'u1',
      'nombre_completo': 'Ana López',
      'correo': 'ana@empresa.com',
      'estado': 'ACTIVO',
      'mfa_enrolado': true,
      'ultimo_acceso': null,
    },
    'tenant': {
      'id': 't1',
      'slug': 'empresa',
      'razon_social': 'Empresa SA',
      'estado': 'ACTIVO',
      'plan': 'PRO',
    },
    'roles': esAdmin ? ['TENANT_ADMIN'] : ['Almacenista'],
    'es_admin': esAdmin,
    'permisos': [
      for (final codigo in permisos)
        {
          'codigo': codigo,
          'dominio': codigo.split(':').first,
          'recurso': codigo.split(':')[1],
          'accion': codigo.split(':').last,
        },
    ],
    'modulos': [
      {'codigo': 'INVENTARIO', 'nombre': 'Inventario', 'fase': 1},
    ],
  });
}

void main() {
  group('ContextoSesion.fromJson', () {
    test('extrae los codigos de permiso del catalogo anidado', () {
      final contexto = _contextoCon([
        Permisos.productosLeer,
        Permisos.stockLeer,
      ]);

      expect(contexto.permisos, {Permisos.productosLeer, Permisos.stockLeer});
      expect(contexto.modulos, {'INVENTARIO'});
      expect(contexto.usuario.nombreCompleto, 'Ana López');
      expect(contexto.tenant.slug, 'empresa');
    });

    test('las iniciales salen del nombre completo', () {
      expect(_contextoCon([]).usuario.iniciales, 'AL');
    });
  });

  group('visibilidad de modulos', () {
    test('un almacenista solo ve inventario', () {
      final contexto = _contextoCon([
        Permisos.productosLeer,
        Permisos.stockLeer,
        Permisos.movimientosCrear,
      ]);

      expect(contexto.puedeAlguno(Permisos.puertaInventario), isTrue);
      expect(contexto.puedeAlguno(Permisos.puertaReportes), isFalse);
      expect(contexto.puedeAlguno(Permisos.puertaPersonal), isFalse);
    });

    test('el TENANT_ADMIN recibe el catalogo completo y ve las tres secciones', () {
      // El backend expande el bypass del rol de sistema antes de responder,
      // asi que /me/ ya trae todos los codigos aplicables al tenant.
      final contexto = _contextoCon([
        ...Permisos.puertaInventario,
        ...Permisos.puertaReportes,
        ...Permisos.puertaPersonal,
      ], esAdmin: true);

      expect(contexto.esAdmin, isTrue);
      expect(contexto.puedeAlguno(Permisos.puertaInventario), isTrue);
      expect(contexto.puedeAlguno(Permisos.puertaReportes), isTrue);
      expect(contexto.puedeAlguno(Permisos.puertaPersonal), isTrue);
    });

    test('un rol intermedio ve reportes sin ver personal', () {
      // El caso que justifica derivar la UI de permisos y no del nombre del rol.
      final contexto = _contextoCon([
        Permisos.stockLeer,
        Permisos.valuacionLeer,
        Permisos.kardexLeer,
      ]);

      expect(contexto.puedeAlguno(Permisos.puertaInventario), isTrue);
      expect(contexto.puedeAlguno(Permisos.puertaReportes), isTrue);
      expect(contexto.puedeAlguno(Permisos.puertaPersonal), isFalse);
    });

    test('sin permisos no se abre ninguna seccion', () {
      final contexto = _contextoCon([]);

      expect(contexto.puedeAlguno(Permisos.puertaInventario), isFalse);
      expect(contexto.puedeAlguno(Permisos.puertaReportes), isFalse);
      expect(contexto.puedeAlguno(Permisos.puertaPersonal), isFalse);
      expect(contexto.rolPrincipal, 'Almacenista');
    });
  });

  group('acciones dentro de un modulo', () {
    test('leer no implica crear', () {
      final contexto = _contextoCon([Permisos.productosLeer]);

      expect(contexto.puede(Permisos.productosLeer), isTrue);
      expect(contexto.puede(Permisos.productosCrear), isFalse);
      expect(
        contexto.puedeTodos([Permisos.productosLeer, Permisos.productosCrear]),
        isFalse,
      );
    });
  });
}
