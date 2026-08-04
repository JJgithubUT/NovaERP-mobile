import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final usuario = authProvider.usuario;

    // --- PALETA DE COLORES CORPORATIVA ---
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
          'Mi Perfil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        // --- FLECHA DE REGRESO A HOME ---
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          children: [
            // --- SECCIÓN DE AVATAR Y ENCABEZADO ---
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: negroProfundo.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 55,
                      backgroundColor: guindaBase,
                      child: Icon(Icons.person, size: 55, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    usuario?.nombre ?? 'Nombre no disponible',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: negroProfundo,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rol: ${usuario?.rol ?? "Usuario"}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: rojoVivo.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // --- SECCIÓN: INFORMACIÓN DE LA CUENTA ---
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Información de la Cuenta",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: negroProfundo,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: grisMedio.withOpacity(0.2), width: 1),
              ),
              child: Column(
                children: [
                  _buildProfileTile(
                    icon: Icons.email_outlined,
                    title: 'Correo Electrónico',
                    subtitle: usuario?.email ?? 'correo@novaerp.com',
                    iconColor: negroProfundo.withOpacity(0.7),
                  ),
                  const Divider(height: 1, color: fondoPrincipal, indent: 56),
                  _buildProfileTile(
                    icon: Icons.shield_outlined,
                    title: 'Seguridad',
                    subtitle: 'Contraseña y accesos verificados',
                    iconColor: negroProfundo.withOpacity(0.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- SECCIÓN: ACCIONES / CERRAR SESIÓN ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: grisMedio.withOpacity(0.2), width: 1),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => false,
                      );
                    }
                  },
                  splashColor: rojoVivo.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(
                              0xFFFDF2F3,
                            ), // Fondo rojo suave constante
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.logout, color: rojoVivo, size: 22),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Cerrar Sesión',
                            style: TextStyle(
                              color: rojoVivo,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: grisMedio,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper estético para las filas de información
  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFAFAFAF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF0D0D0D),
                    fontWeight: FontWeight.w600,
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
