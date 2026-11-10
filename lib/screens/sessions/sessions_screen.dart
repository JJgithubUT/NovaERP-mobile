/// HU19 - Consulta y revocacion de sesiones activas.
///
/// Muestra solo las sesiones del propio usuario. Permite cerrar una sesion
/// remota o todas las demas. La sesion actual aparece marcada y no se puede
/// revocar desde aqui (para eso esta "Cerrar sesion" del perfil). Si el backend
/// responde 401, ApiClient limpia la sesion y AuthGate vuelve al login.
import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../models/sesion.dart';
import '../../services/sesiones_service.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final _service = SesionesService();

  List<Sesion> _sesiones = const [];
  bool _cargando = true;
  bool _trabajando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final sesiones = await _service.listar();
      if (!mounted) return;
      setState(() {
        _sesiones = sesiones;
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _cargando = false;
      });
    }
  }

  Future<bool> _confirmar(String titulo, String mensaje) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: AppColors.primaryLight),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _revocar(Sesion sesion) async {
    final ok = await _confirmar(
      'Cerrar sesión',
      'Se cerrará la sesión en "${sesion.tipo.etiqueta}". Quien la use tendrá '
          'que iniciar sesión de nuevo.',
    );
    if (!ok || !mounted) return;

    setState(() => _trabajando = true);
    try {
      await _service.revocar(sesion.jti);
      if (!mounted) return;
      _aviso('Sesión cerrada.');
    } on ApiException catch (e) {
      if (!mounted) return;
      _aviso(e.mensaje);
    }
    if (!mounted) return;
    setState(() => _trabajando = false);
    await _cargar();
  }

  Future<void> _cerrarOtras() async {
    final ok = await _confirmar(
      'Cerrar las demás sesiones',
      'Se cerrarán todas las sesiones excepto la de este dispositivo.',
    );
    if (!ok || !mounted) return;

    setState(() => _trabajando = true);
    try {
      final n = await _service.cerrarOtras();
      if (!mounted) return;
      _aviso(n == 0 ? 'No había otras sesiones.' : 'Sesiones cerradas: $n.');
    } on ApiException catch (e) {
      if (!mounted) return;
      _aviso(e.mensaje);
    }
    if (!mounted) return;
    setState(() => _trabajando = false);
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final hayOtras = _sesiones.any((s) => !s.actual);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Sesiones activas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _cuerpo(hayOtras),
    );
  }

  Widget _cuerpo(bool hayOtras) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _cargar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_sesiones.isEmpty) {
      return const Center(child: Text('No hay sesiones activas.'));
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final sesion in _sesiones)
            _TarjetaSesion(
              sesion: sesion,
              deshabilitado: _trabajando,
              onCerrar: () => _revocar(sesion),
            ),
          if (hayOtras) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _trabajando ? null : _cerrarOtras,
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar todas las demás sesiones'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TarjetaSesion extends StatelessWidget {
  const _TarjetaSesion({
    required this.sesion,
    required this.deshabilitado,
    required this.onCerrar,
  });

  final Sesion sesion;
  final bool deshabilitado;
  final VoidCallback onCerrar;

  static String _fecha(DateTime? f) {
    if (f == null) return '—';
    final l = f.toLocal();
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(l.day)}/${dos(l.month)}/${l.year} ${dos(l.hour)}:${dos(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sesion.actual
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(sesion.tipo.icono, color: AppColors.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        sesion.tipo.etiqueta,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    if (sesion.actual) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Este dispositivo',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'IP: ${sesion.ipOrigen.isEmpty ? '—' : sesion.ipOrigen}',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
                Text(
                  'Iniciada: ${_fecha(sesion.iniciadaEn)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
                Text(
                  'Expira: ${_fecha(sesion.expiraEn)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ),
          if (!sesion.actual)
            IconButton(
              tooltip: 'Cerrar esta sesión',
              onPressed: deshabilitado ? null : onCerrar,
              icon: const Icon(Icons.logout, color: AppColors.primaryLight),
            ),
        ],
      ),
    );
  }
}
