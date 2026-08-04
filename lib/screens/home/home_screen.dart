import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../reports/reports_screen.dart';
import '../inventory/inventory_screen.dart'; // <-- Importación del nuevo módulo añadida

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  // --- PALETA DE COLORES CORPORATIVA ---
  final Color guindaBase = const Color(0xFF73030D);
  final Color rojoVivo = const Color(0xFF9E1A22);
  final Color negroProfundo = const Color(0xFF0D0D0D);
  final Color grisMedio = const Color(0xFFAFAFAF);

  @override
  Widget build(BuildContext context) {
    // Lista de pantallas principales controladas por el BottomNavigationBar
    final List<Widget> pages = [
      NovaDashboard(
        onModuleTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
      const ReportsScreen(),
      const InventoryScreen(), // <-- Pantalla de Inventario real integrada
      const Center(child: Text('Pantalla de Personal')),
      const Center(child: Text('Pantalla de Configuración')),
    ];

    return Scaffold(
      body: pages[currentIndex],

      // --- BOTTOM NAVIGATION BAR ULTRA CLEAN ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: grisMedio.withOpacity(0.2), width: 1.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: guindaBase,
          unselectedItemColor: grisMedio,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: -0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          elevation: 0,
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: "Inicio",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: "Reportes",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: "Inventario",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people_alt),
              label: "Personal",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_suggest_outlined),
              activeIcon: Icon(Icons.settings_suggest),
              label: "Ajustes",
            ),
          ],
        ),
      ),
    );
  }
}

// --- PANEL DE CONTROL PRINCIPAL DE NOVAERP ---
class NovaDashboard extends StatelessWidget {
  final Function(int) onModuleTap;

  const NovaDashboard({Key? key, required this.onModuleTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final usuario = authProvider.usuario;

    const Color guindaBase = Color(0xFF73030D);
    const Color rojoVivo = Color(0xFF9E1A22);
    const Color fondoPrincipal = Color(0xFFF2F2F2);
    const Color negroProfundo = Color(0xFF0D0D0D);
    const Color grisMedio = Color(0xFFAFAFAF);

    return Scaffold(
      backgroundColor: fondoPrincipal,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: negroProfundo,
        title: const Text(
          'NovaERP',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(
                Icons.account_circle_outlined,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // --- BANNER DE BIENVENIDA Y ROL ---
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: rojoVivo.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.waving_hand_outlined,
                          color: rojoVivo,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenido,',
                            style: TextStyle(
                              fontSize: 14,
                              color: negroProfundo.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            usuario?.nombre ?? "Usuario",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: negroProfundo,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Badge de Rol
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: grisMedio.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 14,
                          color: guindaBase,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Rol: ${usuario?.rol ?? "Administrador"}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: negroProfundo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: grisMedio, thickness: 0.5),
                  const SizedBox(height: 8),
                  const Text(
                    "Módulos Operativos",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: negroProfundo,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- GRID DE MENÚS CON ACCIÓN DIRECTA ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.05,
              children: [
                _buildMenuCard(
                  icon: Icons.analytics_outlined,
                  title: 'Reportes',
                  iconColor: guindaBase,
                  badgeText: 'Métricas',
                  onTap: () => onModuleTap(1),
                ),
                _buildMenuCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventario',
                  iconColor: rojoVivo,
                  badgeText: 'Stock',
                  onTap: () => onModuleTap(2),
                ),
                _buildMenuCard(
                  icon: Icons.people_alt_outlined,
                  title: 'Personal',
                  iconColor: guindaBase,
                  badgeText: 'RH',
                  onTap: () => onModuleTap(3),
                ),
                _buildMenuCard(
                  icon: Icons.settings_suggest_outlined,
                  title: 'Configuración',
                  iconColor: negroProfundo.withOpacity(0.7),
                  badgeText: 'Sistema',
                  onTap: () => onModuleTap(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color iconColor,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D0D0D).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFAFAFAF).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: iconColor.withOpacity(0.05),
          highlightColor: iconColor.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 28, color: iconColor),
                    ),
                    Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D0D0D),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D0D0D),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Gestionar',
                          style: TextStyle(
                            fontSize: 12,
                            color: iconColor.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: iconColor.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
