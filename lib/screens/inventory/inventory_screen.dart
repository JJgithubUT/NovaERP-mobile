import 'package:flutter/material.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // --- PALETA DE COLORES CORPORATIVA ---
  final Color guindaBase = const Color(0xFF73030D);
  final Color rojoVivo = const Color(0xFF9E1A22);
  final Color fondoPrincipal = const Color(0xFFF2F2F2);
  final Color negroProfundo = const Color(0xFF0D0D0D);
  final Color grisMedio = const Color(0xFFAFAFAF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoPrincipal,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: negroProfundo,
        title: const Text(
          'Control de Inventario',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // --- BARRA SUPERIOR DE BÚSQUEDA ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar productos, SKU o almacén...',
                hintStyle: TextStyle(color: grisMedio, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: grisMedio),
                filled: true,
                fillColor: fondoPrincipal,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // --- CONTENIDO SCROLLABLE ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Métrica Rápida de Inventario
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: grisMedio.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total del stock",
                              style: TextStyle(
                                color: grisMedio,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "\$1,245,800.00",
                              style: TextStyle(
                                color: negroProfundo,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: rojoVivo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "4 Almacenes",
                            style: TextStyle(
                              color: rojoVivo,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título de sección
                  const Text(
                    "----TEXTO",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Alerta Crítica (Falta Stock)
                  _buildAlertCard(
                    product: "----TEXTO",
                    sku: "SKU-90210",
                    status: "Stock Bajo (2 uds.)",
                    statusColor: rojoVivo,
                  ),
                  const SizedBox(height: 24),

                  // Lista General de Productos
                  const Text(
                    "----TEXTO",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: grisMedio.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        _buildProductItem(
                          "Servidor Rack 2U Intel",
                          "SKU-4402",
                          "45 unidades",
                          "Pasillo A / Estante 3",
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildProductItem(
                          "Cable de Fibra Óptica 10m",
                          "SKU-8812",
                          "120 unidades",
                          "Pasillo B / Estante 1",
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildProductItem(
                          "Módulo de Memoria RAM 32GB",
                          "SKU-1192",
                          "88 unidades",
                          "Pasillo A / Estante 5",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: guindaBase,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Tarjeta de alerta rápida
  Widget _buildAlertCard({
    required String product,
    required String sku,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: statusColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(sku, style: TextStyle(color: grisMedio, fontSize: 12)),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Fila del listado de productos
  Widget _buildProductItem(
    String name,
    String sku,
    String qty,
    String location,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: fondoPrincipal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: guindaBase,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$sku  •  $location",
                  style: TextStyle(color: grisMedio, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            qty,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
