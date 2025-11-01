import 'package:flutter/material.dart';

class HistorialPage extends StatelessWidget {
  const HistorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo (puedes conectarlo luego con tu base de datos)
    final List<Map<String, String>> eventos = [
      {
        "fecha": "16/10/2025",
        "hora": "10:23",
        "descripcion": "Sensor 1 detectó fuga leve",
      },
      {
        "fecha": "15/10/2025",
        "hora": "08:10",
        "descripcion": "Reinicio del sistema completado",
      },
      {
        "fecha": "14/10/2025",
        "hora": "15:45",
        "descripcion": "Mantenimiento preventivo realizado",
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Historial de eventos",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF7B2B),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Encabezado de columnas
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Fecha",
                              textAlign: TextAlign.center, // 🔹 Centrado
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Hora",
                              textAlign: TextAlign.center, // 🔹 Centrado
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              "Descripción",
                              textAlign: TextAlign.center, // 🔹 Centrado
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Filas de datos
                    Expanded(
                      child: ListView.builder(
                        itemCount: eventos.length,
                        itemBuilder: (context, index) {
                          final evento = eventos[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    evento["fecha"]!,
                                    textAlign:
                                        TextAlign.center, // 🔹 Centrado también
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    evento["hora"]!,
                                    textAlign: TextAlign.center, // 🔹 Centrado
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    evento["descripcion"]!,
                                    textAlign: TextAlign.center, // 🔹 Centrado
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
