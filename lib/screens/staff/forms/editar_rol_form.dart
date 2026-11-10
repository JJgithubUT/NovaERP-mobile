import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/campo_formulario.dart';
import '../../../core/widgets/selector_permisos.dart';
import '../../../models/personal.dart';
import '../../../services/personal_service.dart';

/// HU12 - Modificar nombre y permisos de un rol existente. Devuelve true si se
/// guardaron cambios.
///
/// Precarga el rol y envia solo lo que cambio. El conjunto de permisos se manda
/// COMPLETO (el backend lo reemplaza entero). Los cambios surten efecto en la
/// siguiente peticion de cualquier usuario con el rol.
///
/// Los permisos de modulos que la empresa tiene desactivados (`inerte`) no se
/// pueden reenviar: el backend los rechaza. Por eso al guardar se retiran del
/// rol, y el formulario lo avisa antes.
Future<bool> abrirEdicionRol(BuildContext context, Rol rol) async {
  final guardado = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FormularioEdicionRol(rol: rol),
    ),
  );
  return guardado ?? false;
}

const _errorGeneral = 'No fue posible actualizar el rol.';

class _FormularioEdicionRol extends StatefulWidget {
  const _FormularioEdicionRol({required this.rol});

  final Rol rol;

  @override
  State<_FormularioEdicionRol> createState() => _FormularioEdicionRolState();
}

class _FormularioEdicionRolState extends State<_FormularioEdicionRol> {
  final _formKey = GlobalKey<FormState>();
  final _servicio = PersonalService();
  late final _nombre = TextEditingController(text: widget.rol.nombre);

  List<DominioPermisos> _catalogo = const [];

  /// Codigos de los permisos inertes del catalogo: no se pueden enviar.
  Set<String> _inertes = {};

  late Set<String> _permisos = {...widget.rol.codigosPermisos};

  bool _cargandoCatalogo = true;
  String? _errorCatalogo;
  bool _enviando = false;
  String? _error;
  String? _campoConError;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogo() async {
    setState(() {
      _cargandoCatalogo = true;
      _errorCatalogo = null;
    });
    try {
      final catalogo = await _servicio.catalogoPermisos();
      if (!mounted) return;
      setState(() {
        _catalogo = catalogo;
        _inertes = {
          for (final d in catalogo)
            for (final p in d.permisos.where((p) => p.inerte)) p.codigo,
        };
        _cargandoCatalogo = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoCatalogo = false;
        _errorCatalogo = e.esPermisoDenegado
            ? e.mensaje
            : 'No fue posible cargar el catálogo de permisos.';
      });
    }
  }

  /// Permisos del rol que se retirarian por ser de un modulo inactivo.
  Set<String> get _inertesDelRol =>
      widget.rol.codigosPermisos.intersection(_inertes);

  /// Permisos que se enviarian: los elegidos, sin los inertes.
  Set<String> get _permisosAEnviar => _permisos.difference(_inertes);

  /// Solo lo que difiere del rol vigente.
  Map<String, dynamic> _cambios() {
    final cambios = <String, dynamic>{};
    final nombre = _nombre.text.trim();
    if (nombre != widget.rol.nombre) cambios['nombre'] = nombre;

    final originales = widget.rol.codigosPermisos.difference(_inertes);
    final nuevos = _permisosAEnviar;
    final igual =
        originales.length == nuevos.length && originales.containsAll(nuevos);
    // Los permisos solo se envian si el usuario cambio la seleccion. Si solo
    // renombra el rol, el conjunto (con sus permisos inertes) no se toca.
    if (!igual) cambios['permisos'] = nuevos.toList();
    return cambios;
  }

  Future<bool> _confirmar(Map<String, dynamic> cambios) async {
    final n = widget.rol.usuariosAsignados;
    final alcance = n == 0
        ? 'Ningún usuario tiene este rol por ahora.'
        : n == 1
        ? 'Se aplicará de inmediato a 1 usuario con este rol.'
        : 'Se aplicará de inmediato a los $n usuarios con este rol.';
    final retira = _inertesDelRol.isEmpty || !cambios.containsKey('permisos')
        ? ''
        : '\n\nSe retirarán ${_inertesDelRol.length} permisos de módulos '
              'inactivos.';

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar cambios'),
        content: Text('$alcance$retira\n\n¿Desea continuar?'),
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

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cambios = _cambios();
    if (cambios.containsKey('permisos') && _permisosAEnviar.isEmpty) {
      setState(() {
        _error = 'El rol debe conservar al menos un permiso.';
        _campoConError = 'permisos';
      });
      return;
    }
    if (cambios.isEmpty) {
      setState(() {
        _error = 'No hay cambios que guardar.';
        _campoConError = null;
      });
      return;
    }
    if (!await _confirmar(cambios) || !mounted) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _enviando = true;
      _error = null;
      _campoConError = null;
    });

    try {
      await _servicio.editarRol(widget.rol.id, cambios);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        // 403 (rol de sistema) y 422 (nombre repetido, permisos invalidos)
        // traen un mensaje especifico; el resto usa el texto general.
        _error = e.esReglaDeNegocio || e.esPermisoDenegado
            ? e.mensaje
            : _errorGeneral;
        _campoConError = e.campo;
      });
    } catch (_) {
      // Cualquier otro fallo: el formulario nunca debe quedarse girando.
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = _errorGeneral;
        _campoConError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedeGuardar =
        !_enviando && !_cargandoCatalogo && _errorCatalogo == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Editar rol',
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
                etiqueta: 'Nombre del rol',
                controlador: _nombre,
                habilitado: !_enviando,
                resaltado: _campoConError == 'nombre',
                // Al corregir el nombre se quita el error que dejo el servidor
                // (por ejemplo "ya existe un rol con ese nombre").
                onCambio: (_) {
                  if (_campoConError == 'nombre') {
                    setState(() {
                      _campoConError = null;
                      _error = null;
                    });
                  }
                },
                validador: (v) {
                  final texto = v?.trim() ?? '';
                  if (texto.isEmpty) return 'El nombre es obligatorio';
                  if (texto.length > 100) {
                    return 'El nombre no puede pasar de 100 caracteres';
                  }
                  return null;
                },
              ),
              Row(
                children: [
                  const Text(
                    'Permisos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· ${_permisosAEnviar.length} seleccionados',
                    style: TextStyle(
                      fontSize: 12,
                      color: _campoConError == 'permisos'
                          ? AppColors.primary
                          : AppColors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_cargandoCatalogo)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_errorCatalogo != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Text(
                        _errorCatalogo!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.warning),
                      ),
                      TextButton(
                        onPressed: _cargarCatalogo,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              else ...[
                if (_inertesDelRol.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Este rol tiene ${_inertesDelRol.length} permisos de '
                      'módulos inactivos en la empresa. Si cambia la selección '
                      'de permisos, se retirarán del rol al guardar.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.black,
                        height: 1.35,
                      ),
                    ),
                  ),
                SelectorPermisos(
                  catalogo: _catalogo,
                  seleccionados: _permisos,
                  habilitado: !_enviando,
                  resaltado: _campoConError == 'permisos',
                  onCambio: (nuevo) => setState(() {
                    _permisos = nuevo;
                    if (_campoConError == 'permisos') {
                      _campoConError = null;
                      _error = null;
                    }
                  }),
                ),
              ],

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
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: puedeGuardar ? _guardar : null,
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
