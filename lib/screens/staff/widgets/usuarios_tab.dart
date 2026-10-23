import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/widgets/lista_paginada.dart';
import '../../../models/personal.dart';
import '../../../services/personal_service.dart';
import '../detalle_usuario.dart';

/// Directorio de usuarios del tenant, con busqueda y filtro por estado.
class UsuariosTab extends StatefulWidget {
  const UsuariosTab({super.key});

  @override
  State<UsuariosTab> createState() => UsuariosTabState();
}

class UsuariosTabState extends State<UsuariosTab> {
  final _servicio = PersonalService();
  final _listaKey = GlobalKey<ListaPaginadaState<UsuarioDirectorio>>();
  final _busquedaController = TextEditingController();

  String _busqueda = '';
  String? _estado;

  static const _estados = {
    'activo': 'Activos',
    'pendiente': 'Pendientes',
    'suspendido': 'Suspendidos',
  };

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void recargar() => _listaKey.currentState?.recargar();

  @override
  Widget build(BuildContext context) {
    return ListaPaginada<UsuarioDirectorio>(
      key: ValueKey('usuarios-$_busqueda-$_estado'),
      cargar: (pagina) => _servicio.usuarios(
        pagina: pagina,
        busqueda: _busqueda.isEmpty ? null : _busqueda,
        estado: _estado,
      ),
      mensajeVacio: _busqueda.isEmpty
          ? 'No hay usuarios con ese criterio'
          : 'Sin resultados para "$_busqueda"',
      iconoVacio: Icons.person_search_outlined,
      cabecera: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, correo o puesto',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busqueda.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _busquedaController.clear();
                          setState(() => _busqueda = '');
                        },
                      ),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.grey.withValues(alpha: 0.3),
                  ),
                ),
              ),
              onSubmitted: (valor) => setState(() => _busqueda = valor.trim()),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _Pastilla(
                  etiqueta: 'Todos',
                  activa: _estado == null,
                  onTap: () => setState(() => _estado = null),
                ),
                for (final e in _estados.entries)
                  _Pastilla(
                    etiqueta: e.value,
                    activa: _estado == e.key,
                    onTap: () => setState(() => _estado = e.key),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
      itemBuilder: (contexto, usuario) => _FilaUsuario(
        usuario: usuario,
        onAbrir: () async {
          final cambio = await abrirDetalleUsuario(contexto, usuario);
          if (cambio) recargar();
        },
      ),
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

class _FilaUsuario extends StatelessWidget {
  const _FilaUsuario({required this.usuario, required this.onAbrir});

  final UsuarioDirectorio usuario;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final (color, etiqueta) = switch (usuario.estado.toLowerCase()) {
      'activo' => (AppColors.success, null),
      'suspendido' => (AppColors.primaryLight, 'Suspendido'),
      'pendiente' => (AppColors.warning, 'Pendiente'),
      _ => (AppColors.grey, usuario.estado),
    };

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onAbrir,
      leading: CircleAvatar(
        radius: 21,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Text(
          usuario.iniciales,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              usuario.nombreCompleto,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
              ),
            ),
          ),
          if (etiqueta != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                etiqueta,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          '${usuario.correo}\n'
          '${usuario.roles.isEmpty ? 'Sin roles' : usuario.roles.join(' · ')}'
          '${usuario.ultimoAcceso == null ? '' : ' · ${Formato.fechaHora(usuario.ultimoAcceso)}'}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.grey,
            height: 1.4,
          ),
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
