import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';

/// Pantalla temporal mientras se implementa la funcionalidad.
class DetalleEvento extends StatelessWidget {
  const DetalleEvento({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Detalle del evento',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: const Center(
        child: Text(
          'Esta funcionalidad aún no está disponible.',
          style: TextStyle(fontSize: 14, color: AppColors.grey),
        ),
      ),
    );
  }
}
