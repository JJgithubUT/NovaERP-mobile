import 'package:flutter/material.dart';

/// HU19 - Sesion activa del usuario (GET /api/core/sesiones/).
///
/// Forma de cada elemento de `results`:
///   id, jti, dispositivo (User-Agent crudo), ip_origen, iniciada_en,
///   ultima_actividad, expira_en (ISO 8601) y `actual` (true = esta sesion).
/// El tipo de dispositivo se deriva del User-Agent en la app.
class Sesion {
  final String id;
  final String jti;

  /// User-Agent crudo tal como lo guarda el backend.
  final String dispositivo;
  final String ipOrigen;
  final DateTime? iniciadaEn;
  final DateTime? ultimaActividad;
  final DateTime? expiraEn;

  /// True si es la sesion desde la que se esta consultando.
  final bool actual;

  const Sesion({
    required this.id,
    required this.jti,
    required this.dispositivo,
    required this.ipOrigen,
    required this.actual,
    this.iniciadaEn,
    this.ultimaActividad,
    this.expiraEn,
  });

  factory Sesion.fromJson(Map<String, dynamic> json) {
    DateTime? fecha(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return Sesion(
      id: json['id']?.toString() ?? '',
      jti: json['jti']?.toString() ?? '',
      dispositivo: json['dispositivo']?.toString() ?? '',
      ipOrigen: json['ip_origen']?.toString() ?? '',
      iniciadaEn: fecha(json['iniciada_en']),
      ultimaActividad: fecha(json['ultima_actividad']),
      expiraEn: fecha(json['expira_en']),
      actual: json['actual'] == true,
    );
  }

  /// Tipo de dispositivo deducido del User-Agent (el backend no lo parsea).
  TipoDispositivo get tipo {
    final ua = dispositivo.toLowerCase();
    if (ua.contains('android') ||
        ua.contains('iphone') ||
        ua.contains('ipad') ||
        ua.contains('mobile') ||
        ua.contains('dart') ||
        ua.contains('okhttp')) {
      return TipoDispositivo.movil;
    }
    if (ua.contains('mozilla') ||
        ua.contains('chrome') ||
        ua.contains('safari') ||
        ua.contains('firefox') ||
        ua.contains('edg')) {
      return TipoDispositivo.navegador;
    }
    return TipoDispositivo.desconocido;
  }
}

enum TipoDispositivo {
  movil('Dispositivo móvil', Icons.smartphone),
  navegador('Navegador web', Icons.language),
  desconocido('Dispositivo desconocido', Icons.devices_other);

  const TipoDispositivo(this.etiqueta, this.icono);

  final String etiqueta;
  final IconData icono;
}
