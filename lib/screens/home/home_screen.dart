import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../profile/profile_screen.dart';
import '../staff/staff_screen.dart';

/// Contenedor principal tras el login: panel de inicio y perfil.
///
/// Los modulos de negocio (inventario, reportes, personal) se agregan en
/// sprints posteriores; sus secciones se derivan de los permisos efectivos de
/// `/api/core/me/` (ver `AuthProvider.veInventario` y similares), no del
/// nombre del rol.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Las secciones salen de los permisos efectivos, no del nombre del rol.
    final secciones = <_Seccion>[
      const _Seccion(
        etiqueta: 'Inicio',
        icono: Icons.home_outlined,
        iconoActivo: Icons.home,
        pantalla: _PanelInicio(),
      ),
      if (auth.vePersonal)
        const _Seccion(
          etiqueta: 'Personal',
          icono: Icons.people_alt_outlined,
          iconoActivo: Icons.people_alt,
          pantalla: StaffScreen(),
        ),
      const _Seccion(
        etiqueta: 'Perfil',
        icono: Icons.account_circle_outlined,
        iconoActivo: Icons.account_circle,
        pantalla: ProfileScreen(),
      ),
    ];

    // Si los permisos cambian y desaparece una seccion, el indice no se sale.
    final indice = _indice < secciones.length ? _indice : 0;

    return Scaffold(
      body: IndexedStack(
        index: indice,
        children: [for (final s in secciones) s.pantalla],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: indice,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        onTap: (i) => setState(() => _indice = i),
        items: [
          for (final s in secciones)
            BottomNavigationBarItem(
              icon: Icon(s.icono),
              activeIcon: Icon(s.iconoActivo),
              label: s.etiqueta,
            ),
        ],
      ),
    );
  }
}

class _Seccion {
  const _Seccion({
    required this.etiqueta,
    required this.icono,
    required this.iconoActivo,
    required this.pantalla,
  });

  final String etiqueta;
  final IconData icono;
  final IconData iconoActivo;
  final Widget pantalla;
}

class _PanelInicio extends StatelessWidget {
  const _PanelInicio();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'NovaERP',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${auth.usuario?.nombreCompleto ?? ''}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              auth.contexto?.tenant.razonSocial ?? '',
              style: const TextStyle(fontSize: 14, color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
