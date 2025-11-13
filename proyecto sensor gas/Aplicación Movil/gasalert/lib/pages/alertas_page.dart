import 'package:flutter/material.dart';
import 'nueva_ventana.dart';

class AlertasPage extends StatefulWidget {
  const AlertasPage({super.key});

  @override
  State<AlertasPage> createState() => _AlertasPageState();
}

class _AlertasPageState extends State<AlertasPage> {
  bool isConectado = true; // Estado de conexión inicial

  @override
  Widget build(BuildContext context) {
    // Ejemplo de alertas (puedes reemplazar por datos dinámicos)
    final List<String> alertas = [
      "Temperatura fuera del rango normal",
      "Sensor 3 desconectado",
      "Mantenimiento programado para mañana",
    ];

    // 🔔 Función para mostrar mensajes tipo SnackBar
    void mostrarMensaje(String mensaje, Color color) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje, style: const TextStyle(color: Colors.white)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔘 Botones de estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isConectado = true;
                    });
                  },
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text("Conectado"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConectado ? Colors.green : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isConectado = false;
                    });
                  },
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  label: const Text("Desconectado"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isConectado ? Colors.red : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🧾 Título
            const Text(
              "Alertas de la aplicación",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF7B2B),
              ),
            ),

            const SizedBox(height: 16),

            // 📋 Contenedor de alertas
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.separated(
                  itemCount: alertas.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: Colors.grey[400], thickness: 1),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        alertas[index],
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔘 Botones inferiores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ✅ Botón "Probar alerta"
                ElevatedButton(
                  onPressed: () {
                    mostrarMensaje(
                      "Recibiendo datos del sistema...",
                      Colors.green,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Probar alerta"),
                ),

                // ❌ Botón "Desconectar"
                ElevatedButton(
                  onPressed: () {
                    mostrarMensaje("Aplicación desconectada", Colors.red);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Desconectar"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🪟 Botón "Abrir ventana"
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NuevaVentana()),
                );
              },
              icon: const Icon(Icons.window, color: Colors.white),
              label: const Text(
                "Abrir ventana",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7B2B),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
