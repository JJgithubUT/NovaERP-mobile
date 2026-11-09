import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_colors.dart';
import '../../core/utils/formato.dart';
import '../../models/auditoria.dart';
import '../../providers/auth_provider.dart';

/// HU20 - Detalle de un evento de la bitacora.
///
/// El registro automatico lo hace el backend: cada CREATE, UPDATE o DELETE
/// genera un evento append-only, con los datos sensibles enmascarados como
/// `[REDACTED]`. La app lo muestra tal cual, en solo lectura y sin ninguna
/// accion de edicion o baja.
///
/// Muestra los 7 campos obligatorios del registro: marca de tiempo (UTC),
/// tenant, usuario, IP de origen, tipo de operacion, id de la entidad afectada y
/// el payload diferencial (valores antes y despues).
///
/// Contrato que usa BitacoraTab (HU21): la funcion `abrirDetalleEvento`.
/// [nombreUsuario] es el nombre resuelto del usuario, si se pudo obtener.
Future<void> abrirDetalleEvento(
  BuildContext context,
  EventoAuditoria evento, {
  String? nombreUsuario,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) =>
          _DetalleEvento(evento: evento, nombreUsuario: nombreUsuario),
    ),
  );
}

const _redactado = '[REDACTED]';

const _etiquetasOperacion = {
  'INSERT': 'Alta',
  'UPDATE': 'Cambio',
  'DELETE': 'Baja',
  'LOGIN': 'Ingreso',
  'LOGIN_FAILED': 'Fallo de acceso',
  'ACCOUNT_LOCKED': 'Bloqueo de cuenta',
  'EXPORT': 'Exportación',
};

class _DetalleEvento extends StatelessWidget {
  const _DetalleEvento({required this.evento, this.nombreUsuario});

  final EventoAuditoria evento;
  final String? nombreUsuario;

  /// "2026-11-09 10:48:36 UTC": la hora exacta del registro, sin conversion.
  static String _utc(DateTime? momento) {
    if (momento == null) return '—';
    final u = momento.toUtc();
    String dd(int n, [int ancho = 2]) => n.toString().padLeft(ancho, '0');
    return '${u.year}-${dd(u.month)}-${dd(u.day)} '
        '${dd(u.hour)}:${dd(u.minute)}:${dd(u.second)} UTC';
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<AuthProvider>().contexto?.tenant;
    final operacion = evento.operacion.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Detalle del evento',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _etiquetasOperacion[operacion] ?? evento.operacion,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  evento.entidad,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Evento #${evento.id}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _Seccion(
            titulo: 'Datos del registro',
            hijos: [
              _Fila(
                icono: Icons.schedule_outlined,
                titulo: 'Fecha y hora (UTC)',
                valor: _utc(evento.ocurridoEn),
                detalle: 'En su zona: ${Formato.fechaHora(evento.ocurridoEn)}',
              ),
              _Fila(
                icono: Icons.business_outlined,
                titulo: 'Tenant',
                valor: tenant?.razonSocial ?? '—',
                detalle: tenant?.id,
              ),
              _Fila(
                icono: Icons.person_outline,
                titulo: 'Usuario',
                valor:
                    nombreUsuario ??
                    (evento.usuarioId == null ? 'Sistema' : 'Usuario'),
                detalle: evento.usuarioId,
              ),
              _Fila(
                icono: Icons.public_outlined,
                titulo: 'IP de origen',
                valor: evento.ipOrigen ?? '—',
              ),
              _Fila(
                icono: Icons.bolt_outlined,
                titulo: 'Tipo de operación',
                valor: _etiquetasOperacion[operacion] ?? evento.operacion,
                detalle: evento.operacion,
              ),
              _Fila(
                icono: Icons.dataset_outlined,
                titulo: 'Entidad afectada',
                valor: evento.entidad,
                detalle: evento.entidadId,
              ),
              _Fila(
                icono: Icons.flag_outlined,
                titulo: 'Criticidad',
                valor: evento.criticidad,
              ),
            ],
          ),

          const SizedBox(height: 20),
          _Payload(evento: evento),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 18, color: AppColors.grey),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Los registros de auditoría son de solo lectura: se '
                    'almacenan de forma secuencial y no pueden editarse ni '
                    'borrarse.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Payload diferencial: que cambio. En un UPDATE solo se listan los campos que
/// difieren; en un alta o una baja, todos los valores registrados.
class _Payload extends StatelessWidget {
  const _Payload({required this.evento});

  final EventoAuditoria evento;

  static String _texto(Object? valor) {
    if (valor == null) return '—';
    if (valor is String) return valor;
    if (valor is Map || valor is List) return jsonEncode(valor);
    return valor.toString();
  }

  @override
  Widget build(BuildContext context) {
    final antes = evento.valoresAntes;
    final despues = evento.valoresDespues;

    final filas = <Widget>[];
    String titulo;

    if (antes != null && despues != null) {
      titulo = 'Cambios (antes → después)';
      final claves = {...antes.keys, ...despues.keys}.toList()..sort();
      for (final c in claves) {
        if (_texto(antes[c]) == _texto(despues[c])) continue;
        filas.add(_FilaValor(clave: c, antes: antes[c], despues: despues[c]));
      }
      if (filas.isEmpty) {
        filas.add(
          const ListTile(
            dense: true,
            title: Text(
              'Sin diferencias en los campos registrados.',
              style: TextStyle(fontSize: 13, color: AppColors.grey),
            ),
          ),
        );
      }
    } else if (despues != null) {
      titulo = 'Valores registrados';
      for (final c in (despues.keys.toList()..sort())) {
        filas.add(_FilaValor(clave: c, despues: despues[c]));
      }
    } else if (antes != null) {
      titulo = 'Valores eliminados';
      for (final c in (antes.keys.toList()..sort())) {
        filas.add(_FilaValor(clave: c, antes: antes[c], soloAntes: true));
      }
    } else {
      titulo = 'Payload diferencial';
      filas.add(
        const ListTile(
          dense: true,
          title: Text(
            'Este evento no registra valores.',
            style: TextStyle(fontSize: 13, color: AppColors.grey),
          ),
        ),
      );
    }

    final enmascarados = evento.camposEnmascarados;
    return _Seccion(
      titulo: titulo,
      hijos: [
        if (enmascarados.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppColors.warning.withValues(alpha: 0.08),
            child: Text(
              'Los datos sensibles (${enmascarados.join(', ')}) se guardan '
              'enmascarados como $_redactado.',
              style: const TextStyle(fontSize: 11.5, height: 1.35),
            ),
          ),
        ...filas,
      ],
    );
  }
}

class _FilaValor extends StatelessWidget {
  const _FilaValor({
    required this.clave,
    this.antes,
    this.despues,
    this.soloAntes = false,
  });

  final String clave;
  final Object? antes;
  final Object? despues;
  final bool soloAntes;

  @override
  Widget build(BuildContext context) {
    final mostrarAmbos = antes != null && despues != null && !soloAntes;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            clave,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 3),
          if (mostrarAmbos) ...[
            _Valor(_Payload._texto(antes), tachado: true),
            const SizedBox(height: 2),
            _Valor(_Payload._texto(despues)),
          ] else
            _Valor(_Payload._texto(soloAntes ? antes : (despues ?? antes))),
        ],
      ),
    );
  }
}

class _Valor extends StatelessWidget {
  const _Valor(this.texto, {this.tachado = false});

  final String texto;
  final bool tachado;

  @override
  Widget build(BuildContext context) {
    final enmascarado = texto == _redactado;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (enmascarado) ...[
          const Icon(Icons.lock_outline, size: 14, color: AppColors.warning),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: enmascarado
                  ? AppColors.warning
                  : (tachado ? AppColors.grey : AppColors.black),
              decoration: tachado ? TextDecoration.lineThrough : null,
              fontWeight: enmascarado ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.hijos});

  final String titulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(children: hijos),
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String valor;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icono, size: 20, color: AppColors.grey),
      title: Text(
        titulo,
        style: const TextStyle(fontSize: 12, color: AppColors.grey),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),
          if (detalle != null)
            Text(
              detalle!,
              style: const TextStyle(fontSize: 11, color: AppColors.grey),
            ),
        ],
      ),
    );
  }
}
