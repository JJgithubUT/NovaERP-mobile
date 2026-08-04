import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          'Reportes y Métricas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Resumen Ejecutivo ---
            const Text(
              "Resumen mensual",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: negroProfundo,
              ),
            ),
            const SizedBox(height: 12),

            // Fila de Tarjetas de estado rápido
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: "Rendimiento",
                    value: "94.2%",
                    icon: Icons.trending_up,
                    color: rojoVivo,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: "Operaciones",
                    value: "1,240",
                    icon: Icons.loop,
                    color: guindaBase,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // --- Sección de Gráficos Analíticos Simulados ---
            const Text(
              "Distribución de objetivos",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: negroProfundo,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: grisMedio.withOpacity(0.2), width: 1),
              ),
              child: Column(
                children: [
                  _buildProgressRow("Ventas totales", 0.85, rojoVivo),
                  const SizedBox(height: 16),
                  _buildProgressRow("Eficiencia de procesos", 0.60, guindaBase),
                  const SizedBox(height: 16),
                  _buildProgressRow("Metas", 0.40, grisMedio),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // --- Registro de Actividad ---
            const Text(
              "Últimos reportes generados",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: negroProfundo,
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
                  _buildReportRow("Reporte_financiero.pdf", "Hace 2 horas"),
                  const Divider(height: 1, color: fondoPrincipal, indent: 16),
                  _buildReportRow("Auditoria_inventario_final.xlsx", "Ayer"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para las mini tarjetas de estadísticas fijas
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFAFAFAF).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D0D0D),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFAFAFAF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper para las barras analíticas de progreso
  Widget _buildProgressRow(String label, double progressValue, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF0D0D0D),
              ),
            ),
            Text(
              "${(progressValue * 100).toInt()}%",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressValue,
            backgroundColor: const Color(0xFFF2F2F2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // Helper para el historial de documentos
  Widget _buildReportRow(String filename, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            color: Color(0xFF73030D),
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D0D0D),
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFAFAFAF),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.download_rounded,
            color: Color(0xFFAFAFAF),
            size: 18,
          ),
        ],
      ),
    );
  }
}
