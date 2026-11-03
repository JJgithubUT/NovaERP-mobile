import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/campo_formulario.dart';
import '../../../models/personal.dart';
import '../../../services/personal_service.dart';
import '../widgets/enlace_activacion.dart';

/// Alta de usuario (RF-05). Devuelve true si se creo.
///
/// Al terminar muestra el enlace de activacion, que es la unica vez que el
/// backend lo entrega en claro.
Future<bool> abrirAltaUsuario(BuildContext context) async {
  final creado = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const _FormularioUsuario(),
    ),
  );
  return creado ?? false;
}

class _FormularioUsuario extends StatefulWidget {
  const _FormularioUsuario();

  @override
  State<_FormularioUsuario> createState() => _FormularioUsuarioState();
}

class _FormularioUsuarioState extends State<_FormularioUsuario> {
  final _formKey = GlobalKey<FormState>();
  final _servicio = PersonalService();

  final _correo = TextEditingController();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _puesto = TextEditingController();
  final _departamento = TextEditingController();

  List<Rol> _rolesDisponibles = const [];
  final _rolesElegidos = <String>{};

  bool _cargandoRoles = true;
  bool _enviando = false;
  String? _error;
  String? _campoConError;

  @override
  void initState() {
    super.initState();
    _cargarRoles();
  }

  @override
  void dispose() {
    for (final c in [_correo, _nombre, _telefono, _puesto, _departamento]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarRoles() async {
    try {
      final roles = await _servicio.rolesActivos();
      if (!mounted) return;
      setState(() {
        _rolesDisponibles = roles;
        _cargandoRoles = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoRoles = false;
        // Sin permiso de lectura de roles se puede dar de alta igual; el
        // backend permite crear el usuario sin roles y asignarlos despues.
        if (!e.esPermisoDenegado) _error = e.mensaje;
      });
    }
  }

  Future<void> _crear() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // RF-05/RN04: el backend exige al menos un rol. Avisarlo aqui evita un
    // viaje al servidor para que rebote con un 422.
    if (_rolesElegidos.isEmpty) {
      setState(() {
        _error = 'Debe asignar al menos un rol al usuario.';
        _campoConError = 'roles';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _enviando = true;
      _error = null;
      _campoConError = null;
    });

    try {
      final creado = await _servicio.crearUsuario(
        correo: _correo.text.trim(),
        nombreCompleto: _nombre.text.trim(),
        telefono: _telefono.text.trim(),
        puesto: _puesto.text.trim(),
        departamento: _departamento.text.trim(),
        rolesIds: _rolesElegidos.toList(),
      );

      if (!mounted) return;

      final token = creado.tokenActivacion;
      if (token != null && token.isNotEmpty) {
        await mostrarEnlaceActivacion(
          context,
          nombreUsuario: creado.nombreCompleto,
          correo: creado.correo,
          token: token,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = e.mensaje;
        _campoConError = e.campo;
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
          'Nuevo usuario',
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
                habilitado: !_enviando,
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
                habilitado: !_enviando,
                resaltado: _campoConError == 'puesto',
              ),
              CampoFormulario(
                etiqueta: 'Departamento (opcional)',
                controlador: _departamento,
                habilitado: !_enviando,
                resaltado: _campoConError == 'departamento',
              ),

              Row(
                children: [
                  const Text(
                    'Roles',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· al menos uno',
                    style: TextStyle(
                      fontSize: 12,
                      color: _campoConError == 'roles'
                          ? AppColors.primary
                          : AppColors.grey,
                      fontWeight: _campoConError == 'roles'
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_cargandoRoles)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              else if (_rolesDisponibles.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  // Sin roles no se puede dar de alta a nadie: el backend
                  // rechaza el alta sin al menos uno.
                  child: Text(
                    'No hay roles disponibles, o su cuenta no puede '
                    'consultarlos. Cree un rol desde el portal web antes de '
                    'dar de alta usuarios.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.warning),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final rol in _rolesDisponibles)
                      FilterChip(
                        label: Text(rol.nombre),
                        selected: _rolesElegidos.contains(rol.id),
                        onSelected: _enviando
                            ? null
                            : (elegido) => setState(() {
                                if (elegido) {
                                  _rolesElegidos.add(rol.id);
                                } else {
                                  _rolesElegidos.remove(rol.id);
                                }
                              }),
                        labelStyle: TextStyle(
                          fontSize: 12.5,
                          color: _rolesElegidos.contains(rol.id)
                              ? Colors.white
                              : AppColors.black,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.white,
                        showCheckmark: false,
                        side: BorderSide(
                          color: AppColors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),

              if (_error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.link, size: 16, color: AppColors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Al crearlo recibirá un enlace de activación para '
                        'compartir con la persona. Se muestra una sola vez.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.black,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _enviando ? null : _crear,
                  child: _enviando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Crear usuario',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
