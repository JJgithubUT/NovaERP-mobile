/// Catalogo de codigos de permiso del backend, en un solo lugar.
///
/// El backend NO autoriza por nombre de rol sino por codigo de permiso
/// (`dominio:recurso:accion`); ver core/utils/permissions.py. Un rol es
/// simplemente un paquete de estos codigos, y `GET /api/core/me/` devuelve el
/// conjunto efectivo ya resuelto para el usuario.
///
/// Consecuencia de diseno para la app: la UI se pinta a partir de los permisos,
/// nunca a partir del nombre del rol. Si manana se crea un rol "Supervisor de
/// almacen" con reportes pero sin personal, la app se adapta sin recompilar.
///
/// El TENANT_ADMIN es el unico rol de sistema y hace bypass: el backend le
/// devuelve el catalogo completo aplicable al tenant, asi que aqui no necesita
/// ningun tratamiento especial.
///
/// Importante: esto es solo para pintar la interfaz. La autorizacion real la
/// re-resuelve el backend en cada peticion contra la base de datos, asi que un
/// permiso revocado surte efecto de inmediato aunque la UI aun muestre el boton.
class Permisos {
  // ------------------------------------------------------------- Inventario
  static const productosLeer = 'inventario:productos:leer';
  static const productosCrear = 'inventario:productos:crear';
  static const productosEditar = 'inventario:productos:editar';
  static const productosEliminar = 'inventario:productos:eliminar';

  static const almacenesLeer = 'inventario:almacenes:leer';
  static const almacenesCrear = 'inventario:almacenes:crear';
  static const almacenesEditar = 'inventario:almacenes:editar';
  static const almacenesEliminar = 'inventario:almacenes:eliminar';

  static const movimientosLeer = 'inventario:movimientos:leer';
  static const movimientosCrear = 'inventario:movimientos:crear';

  static const ajustesLeer = 'inventario:ajustes:leer';
  static const ajustesCrear = 'inventario:ajustes:crear';

  static const transferenciasLeer = 'inventario:transferencias:leer';
  static const transferenciasCrear = 'inventario:transferencias:crear';

  static const stockLeer = 'inventario:stock:leer';
  static const kardexLeer = 'inventario:kardex:leer';
  static const valuacionLeer = 'inventario:valuacion:leer';

  static const alertasLeer = 'inventario:alertas:leer';
  static const alertasNotificar = 'inventario:alertas:notificar';

  // ------------------------------------------------------- Personal (core)
  static const usuariosLeer = 'core:usuarios:leer';
  static const usuariosCrear = 'core:usuarios:crear';
  static const usuariosEditar = 'core:usuarios:editar';
  static const usuariosSuspender = 'core:usuarios:suspender';
  static const usuariosResetMfa = 'core:usuarios:reset_mfa';

  static const rolesLeer = 'core:roles:leer';
  static const rolesCrear = 'core:roles:crear';
  static const rolesEditar = 'core:roles:editar';
  static const rolesEliminar = 'core:roles:eliminar';

  static const asignacionesCrear = 'core:asignaciones:crear';
  static const asignacionesEliminar = 'core:asignaciones:eliminar';

  // ------------------------------------------------------- Reportes (core)
  static const reportesLeer = 'core:reportes:leer';
  static const bitacoraLeer = 'core:bitacora:leer';
  static const bitacoraExportar = 'core:bitacora:exportar';

  static const sesionesRevocar = 'core:sesiones:revocar';

  // ----------------------------------------------------------------------
  // Puertas de modulo: que hace falta para que una seccion aparezca siquiera.
  // Basta cualquiera de los codigos de la lista (OR), porque un usuario que
  // solo puede consultar stock ya tiene motivo para entrar a Inventario.
  // ----------------------------------------------------------------------

  static const puertaInventario = [
    productosLeer,
    stockLeer,
    movimientosLeer,
    almacenesLeer,
    ajustesLeer,
    transferenciasLeer,
    alertasLeer,
  ];

  static const puertaReportes = [
    reportesLeer,
    bitacoraLeer,
    valuacionLeer,
    kardexLeer,
  ];

  static const puertaPersonal = [usuariosLeer, rolesLeer];
}
