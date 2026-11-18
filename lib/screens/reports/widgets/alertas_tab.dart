import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/widgets/lista_paginada.dart';
import '../../../models/auditoria.dart';
import '../../../services/auditoria_service.dart';
import '../../audit/detalle_evento.dart';

/// HU25 - Notificaciones automaticas de eventos criticos de seguridad.
///
/// El envio de las notificaciones (correo a los administradores del tenant) es
/// un proceso AUTOMATICO del backend: la app no lo dispara, no lo configura, no
/// ofrece interruptores para desactivarlo y el backend no expone un endpoint para
/// consultar su estado de entrega. Lo que SI puede mostrar con la API actual son
/// los eventos de seguridad de la bitacora que lo originan o lo acompanan, de
/// solo lectura:
///   - `ACCOUNT_LOCKED` (criticidad ALTA): cuenta bloqueada por intentos
///     fallidos. Es el evento que dispara el aviso por correo.
///   - `LOGIN_FAILED`: intento de acceso fallido (contexto; no notifica).
///
/// Al tocar una alerta se abre su detalle en la bitacora (HU20): ese es el
/// "enlace a auditoria". La lista no muestra los valores del evento. El detalle
/// oculta el campo `cuerpo` (puede traer enlaces con tokens) SOLO con la
/// correccion de HU20 del Sprint 8 aplicada (paquete CORRECCION-HU20): debe
/// estar en `main` antes que esta pestana.
///
/// Contrato que usa ReportesScreen: la clase `AlertasTab` (sin parametros).
/// [AlertasTabState.recargar] queda publico para refrescar desde fuera.
class AlertasTab extends StatefulWidget {
  const AlertasTab({super.key});

  @override
  State<AlertasTab> createState() => AlertasTabState();
}

class AlertasTabState extends State<AlertasTab> {
  static const _errorConsulta =
      'No fue posible consultar las alertas de seguridad.';

  /// Eventos que se consultan, por el filtro `operacion` de la bitacora (el
  /// backend no filtra por criticidad).
  static const _tipos = {
    'ACCOUNT_LOCKED': 'Bloqueos de cuenta',
    'LOGIN_FAILED': 'Intentos fallidos',
  };

  final _servicio = AuditoriaService();
  final _listaKey = GlobalKey<ListaPaginadaState<EventoAuditoria>>();

  /// La bitacora solo trae usuario_id; los nombres se resuelven aparte.
  Map<String, String> _nombres = const {};

  /// Lectura del directorio en curso (null = ninguna).
  Future<void>? _lecturaNombres;

  String _operacion = 'ACCOUNT_LOCKED';

  @override
  void initState() {
    super.initState();
    _cargarNombres();
  }

  /// Lee el directorio de usuarios (una sola lectura a la vez) y FUSIONA el
  /// resultado con lo ya resuelto: una lectura interrumpida (red, timeout)
  /// devuelve solo lo leido hasta ahi y no debe borrar nombres que ya se conocian.
  Future<void> _cargarNombres() => _lecturaNombres ??= _leerNombres();

  Future<void> _leerNombres() async {
    try {
      final nombres = await _servicio.nombresDeUsuario();
      if (mounted) setState(() => _nombres = {..._nombres, ...nombres});
    } finally {
      _lecturaNombres = null;
    }
  }

  bool _faltanNombres(List<EventoAuditoria> eventos) => eventos.any(
    (e) => e.usuarioId != null && !_nombres.containsKey(e.usuarioId),
  );

  /// Completa los nombres que faltan en [eventos] (directorio leido a medias, o
  /// usuario creado despues de abrir la pestana). Si ya hay una lectura en curso
  /// (la de initState) se ESPERA a que termine en vez de descartar la peticion, y
  /// solo se relee si despues de ella siguen faltando nombres: como mucho una
  /// lectura extra por carga de la primera pagina, y sin bucles aunque el
  /// directorio no se pueda leer (403).
  Future<void> _completarNombres(List<EventoAuditoria> eventos) async {
    try {
      final enCurso = _lecturaNombres;
      if (enCurso != null) {
        await enCurso;
        if (!mounted || !_faltanNombres(eventos)) return;
      }
      await _cargarNombres();
    } catch (_) {
      // Sin nombres la lista sigue funcionando: muestra el id abreviado.
    }
  }

  /// Vuelve a pedir la primera pagina.
  void recargar() => _listaKey.currentState?.recargar();

  void _elegirTipo(String operacion) {
    if (operacion == _operacion) return;
    setState(() => _operacion = operacion);
    recargar();
  }

  String _nombreDe(String? usuarioId) {
    if (usuarioId == null) return 'Cuenta desconocida';
    return _nombres[usuarioId] ?? 'Usuario ${usuarioId.substring(0, 6)}…';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cuando una cuenta se bloquea por intentos fallidos, el '
                  'sistema avisa por correo a los administradores de la '
                  'organización. Los avisos son automáticos y no se pueden '
                  'desactivar. Aquí se muestran los eventos de seguridad; la '
                  'app no muestra el estado de entrega de los correos.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final e in _tipos.entries)
                _Pastilla(
                  etiqueta: e.value,
                  activa: _operacion == e.key,
                  onTap: () => _elegirTipo(e.key),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListaPaginada<EventoAuditoria>(
            key: _listaKey,
            cargar: (pagina) async {
              final lote = await _servicio.bitacora(
                pagina: pagina,
                operacion: _operacion,
              );
              // Pagina 1 = carga inicial, cambio de pastilla, deslizar para
              // actualizar y "Reintentar". Si alguna fila trae un usuario sin
              // nombre se completa el directorio. Al paginar (pagina > 1) no se
              // vuelve a pedir.
              if (mounted && pagina == 1 && _faltanNombres(lote.elementos)) {
                _completarNombres(lote.elementos);
              }
              return lote;
            },
            mensajeError: _errorConsulta,
            mensajeVacio: _operacion == 'ACCOUNT_LOCKED'
                ? 'No hay cuentas bloqueadas registradas.'
                : 'No hay intentos fallidos registrados.',
            iconoVacio: Icons.shield_outlined,
            itemBuilder: (contexto, evento) => _FilaAlerta(
              evento: evento,
              nombre: _nombreDe(evento.usuarioId),
              onAbrir: () => abrirDetalleEvento(
                contexto,
                evento,
                nombreUsuario: evento.usuarioId == null
                    ? null
                    : _nombres[evento.usuarioId],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Pastilla extends StatelessWidget {
  const _Pastilla({
    required this.etiqueta,
    required this.activa,
    required this.onTap,
  });

  final String etiqueta;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: ChoiceChip(
        label: Text(etiqueta),
        selected: activa,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          fontSize: 12.5,
          color: activa ? Colors.white : AppColors.black,
          fontWeight: activa ? FontWeight.w600 : FontWeight.normal,
        ),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.white,
        showCheckmark: false,
        side: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
      ),
    );
  }
}

class _FilaAlerta extends StatelessWidget {
  const _FilaAlerta({
    required this.evento,
    required this.nombre,
    required this.onAbrir,
  });

  final EventoAuditoria evento;
  final String nombre;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final bloqueo = evento.operacion.toUpperCase() == 'ACCOUNT_LOCKED';
    final critica = evento.criticidad.toUpperCase() == 'ALTA';
    final color = bloqueo ? AppColors.primaryLight : AppColors.warning;

    return ListTile(
      onTap: onAbrir,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 19,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(
          bloqueo ? Icons.lock_outline : Icons.report_gmailerrorred_outlined,
          size: 19,
          color: color,
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              bloqueo ? 'Cuenta bloqueada' : 'Intento fallido',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
              ),
            ),
          ),
          if (critica) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ALTA',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '$nombre\n${Formato.fechaHora(evento.ocurridoEn)}'
        '${evento.ipOrigen == null ? '' : ' · ${evento.ipOrigen}'}',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.grey,
          height: 1.4,
        ),
      ),
      isThreeLine: true,
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.grey,
        size: 20,
      ),
    );
  }
}
