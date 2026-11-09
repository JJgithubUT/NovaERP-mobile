import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/campo_formulario.dart';
import '../../../models/personal.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/personal_service.dart';
import '../widgets/enlace_activacion.dart';

/// HU07 - Edicion de un usuario existente. Devuelve true si se guardaron
/// cambios.
///
/// Precarga los datos vigentes, aplica las mismas validaciones del alta
/// (HU05), pide confirmacion explicita y envia SOLO los campos que cambiaron.
/// Si cambia el correo el backend deja al usuario en "pendiente de
/// verificacion" y devuelve un token nuevo, que se muestra igual que en el alta.
///
/// Los roles NO se editan aqui: se gestionan en HU14/HU15.
Future<bool> abrirEdicionUsuario(
  BuildContext context,
  UsuarioDirectorio usuario,
) async {
  final guardado = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FormularioEdicion(usuario: usuario),
    ),
  );
  return guardado ?? false;
}

class _FormularioEdicion extends StatefulWidget {
  const _FormularioEdicion({required this.usuario});

  final UsuarioDirectorio usuario;

  @override
  State<_FormularioEdicion> createState() => _FormularioEdicionState();
}

class _FormularioEdicionState extends State<_FormularioEdicion> {
  final _formKey = GlobalKey<FormState>();
  final _servicio = PersonalService();

  late final _correo = TextEditingController(text: widget.usuario.correo);
  late final _nombre = TextEditingController(
    text: widget.usuario.nombreCompleto,
  );
  late final _telefono = TextEditingController(
    text: widget.usuario.telefono ?? '',
  );
  late final _puesto = TextEditingController(text: widget.usuario.puesto ?? '');
  late final _departamento = TextEditingController(
    text: widget.usuario.departamento ?? '',
  );

  bool _enviando = false;
  String? _error;
  String? _campoConError;

  /// El backend solo deja que cada quien edite su nombre y su telefono; correo,
  /// puesto y departamento los cambia un administrador sobre otra persona.
  bool get _esPropio =>
      context.read<AuthProvider>().contexto?.usuario.id == widget.usuario.id;

  @override
  void dispose() {
    for (final c in [_correo, _nombre, _telefono, _puesto, _departamento]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Solo lo que difiere de los datos vigentes.
  Map<String, dynamic> _cambios() {
    final u = widget.usuario;
    final cambios = <String, dynamic>{};
    void comparar(String clave, String nuevo, String? actual) {
      if (nuevo.trim() != (actual ?? '')) cambios[clave] = nuevo.trim();
    }

    comparar('nombre_completo', _nombre.text, u.nombreCompleto);
    comparar('telefono', _telefono.text, u.telefono);
    if (!_esPropio) {
      comparar('correo', _correo.text, u.correo);
      comparar('puesto', _puesto.text, u.puesto);
      comparar('departamento', _departamento.text, u.departamento);
    }
    return cambios;
  }

  Future<bool> _confirmar() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar cambios'),
        content: const Text(
          'Los cambios modificarán permanentemente la información del usuario. '
          '¿Desea continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Guardar',
              style: TextStyle(color: AppColors.primaryLight),
            ),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  String _mensajeDe(ApiException e) {
    // Mensajes diferenciados: permisos, usuario inexistente, y el resto
    // (correo duplicado, datos invalidos) los trae el backend en `mensaje`.
    if (e.esPermisoDenegado) {
      return 'No tiene permisos para editar usuarios.';
    }
    if (e.statusCode == 404) return 'El usuario ya no existe.';
    return e.mensaje;
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cambios = _cambios();
    if (cambios.isEmpty) {
      setState(() => _error = 'No hay cambios que guardar.');
      return;
    }
    if (!await _confirmar() || !mounted) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _enviando = true;
      _error = null;
      _campoConError = null;
    });

    try {
      final resultado = await _servicio.editarUsuario(
        widget.usuario.id,
        cambios,
      );
      if (!mounted) return;

      final token = resultado.tokenActivacion;
      if (cambios.containsKey('correo') && token != null && token.isNotEmpty) {
        await mostrarEnlaceActivacion(
          context,
          nombreUsuario: resultado.nombreCompleto,
          correo: resultado.correo,
          token: token,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = _mensajeDe(e);
        _campoConError = e.campo;
      });
    } catch (_) {
      // Cualquier otro fallo (red caida, respuesta inesperada, un error de
      // programacion): el formulario nunca debe quedarse girando.
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = 'No se pudo guardar. Revise su conexión e intente de nuevo.';
        _campoConError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Editar usuario',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CampoFormulario(
                etiqueta: 'Correo electrónico',
                controlador: _correo,
                habilitado: !_enviando && !_esPropio,
                tipo: TextInputType.emailAddress,
                resaltado: _campoConError == 'correo',
                validador: (v) {
                  final texto = v?.trim() ?? '';
                  if (texto.isEmpty) return 'El correo es obligatorio';
                  if (texto.length > 150) {
                    return 'El correo no puede pasar de 150 caracteres';
                  }
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto)) {
                    return 'Correo no válido';
                  }
                  return null;
                },
              ),
              CampoFormulario(
                etiqueta: 'Nombre completo',
                controlador: _nombre,
                habilitado: !_enviando,
                resaltado: _campoConError == 'nombre_completo',
                validador: (v) => (v?.trim().isEmpty ?? true)
                    ? 'El nombre es obligatorio'
                    : null,
              ),
              CampoFormulario(
                etiqueta: 'Teléfono (opcional)',
                controlador: _telefono,
                habilitado: !_enviando,
                tipo: TextInputType.phone,
                resaltado: _campoConError == 'telefono',
              ),
              CampoFormulario(
                etiqueta: 'Puesto (opcional)',
                controlador: _puesto,
                habilitado: !_enviando && !_esPropio,
                resaltado: _campoConError == 'puesto',
              ),
              CampoFormulario(
                etiqueta: 'Departamento (opcional)',
                controlador: _departamento,
                habilitado: !_enviando && !_esPropio,
                resaltado: _campoConError == 'departamento',
              ),
              if (_esPropio)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Solo puede modificar su nombre y su teléfono. El correo, '
                    'el puesto y el departamento los cambia un administrador.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.grey),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _enviando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
