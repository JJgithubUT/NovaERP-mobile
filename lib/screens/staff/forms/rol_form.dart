import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/campo_formulario.dart';
import '../../../core/widgets/selector_permisos.dart';
import '../../../models/personal.dart';
import '../../../services/personal_service.dart';

/// HU10 - Crear rol de trabajo. Devuelve true si se creo.
///
/// El selector solo ofrece permisos del catalogo maestro, agrupados por
/// dominio (`GET /api/core/permisos/`). Se bloquea el guardado sin nombre y sin
/// al menos un permiso; el nombre repetido dentro de la empresa lo rechaza el
/// backend (422, campo 'nombre') y se muestra junto al campo.
///
/// Contrato que usa StaffScreen: la funcion `abrirAltaRol`.
Future<bool> abrirAltaRol(BuildContext context) async {
  final creado = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const _FormularioRol(),
    ),
  );
  return creado ?? false;
}

const _errorGeneral =
    'No fue posible crear el rol. Verifique los datos e intente nuevamente.';

class _FormularioRol extends StatefulWidget {
  const _FormularioRol();

  @override
  State<_FormularioRol> createState() => _FormularioRolState();
}

class _FormularioRolState extends State<_FormularioRol> {
  final _formKey = GlobalKey<FormState>();
  final _servicio = PersonalService();
  final _nombre = TextEditingController();

  List<DominioPermisos> _catalogo = const [];
  Set<String> _permisos = {};

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

  Future<void> _crear() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // CU3: sin al menos un permiso no se guarda. Se avisa aqui para no hacer un
    // viaje al servidor que rebotaria con un 422.
    if (_permisos.isEmpty) {
      setState(() {
        _error = 'Debe seleccionar al menos un permiso.';
        _campoConError = 'permisos';
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
      await _servicio.crearRol(
        nombre: _nombre.text.trim(),
        permisos: _permisos,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        // Las reglas de negocio (nombre repetido, permisos invalidos) traen un
        // mensaje especifico; cualquier otra falla usa el texto general.
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
    final puedeGuardar = !_enviando && !_cargandoCatalogo && _errorCatalogo == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Nuevo rol',
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
                    _permisos.isEmpty
                        ? '· al menos uno'
                        : '· ${_permisos.length} seleccionados',
                    style: TextStyle(
                      fontSize: 12,
                      color: _campoConError == 'permisos'
                          ? AppColors.primary
                          : AppColors.grey,
                      fontWeight: _campoConError == 'permisos'
                          ? FontWeight.w600
                          : FontWeight.normal,
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
                _ErrorCatalogo(mensaje: _errorCatalogo!, onReintentar: _cargarCatalogo)
              else
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
                  onPressed: puedeGuardar ? _crear : null,
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
                      : const Text('Crear rol'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCatalogo extends StatelessWidget {
  const _ErrorCatalogo({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.warning),
          ),
          TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
