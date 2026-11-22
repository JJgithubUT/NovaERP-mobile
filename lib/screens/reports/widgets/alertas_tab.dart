import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';

/// HU25 - Notificaciones automaticas de eventos criticos de seguridad.
///
/// El envio de las notificaciones (correo al TENANT_ADMIN y canal adicional) es
/// un proceso AUTOMATICO del backend: la app no lo dispara, no lo configura y
/// el backend no expone un endpoint para consultarlas. Lo que la app puede
/// mostrar con la API actual son los propios eventos de seguridad de la
/// bitacora (por ejemplo `LOGIN_FAILED` y `ACCOUNT_LOCKED`), que son los que
/// originan esas notificaciones.
///
/// Guia: lista de solo lectura de esos eventos (`AuditoriaService.bitacora` con
/// el filtro `operacion`), de lo mas reciente a lo mas antiguo. Al tocar una
/// alerta se abre su detalle en la bitacora con `abrirDetalleEvento`
/// (screens/audit/detalle_evento.dart): ese es el "enlace a auditoria". Nunca
/// mostrar credenciales ni tokens. Aclarar en pantalla que las notificaciones
/// no se pueden desactivar.
///
/// Error: "No fue posible enviar la notificacion de seguridad." es del backend;
/// para la consulta usar un mensaje propio.
///
/// Contrato que usa ReportesScreen: la clase `AlertasTab`. Conservar el nombre.
class AlertasTab extends StatefulWidget {
  const AlertasTab({super.key});

  @override
  State<AlertasTab> createState() => AlertasTabState();
}

class AlertasTabState extends State<AlertasTab> {
  /// Vuelve a pedir la primera pagina.
  void recargar() {
    // TODO(HU25): recargar la lista paginada.
  }

  @override
  Widget build(BuildContext context) {
    // TODO(HU25): reemplazar este marcador por las alertas.
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'HU25: alertas de seguridad pendientes.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.grey),
        ),
      ),
    );
  }
}
