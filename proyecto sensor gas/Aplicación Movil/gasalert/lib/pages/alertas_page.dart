import 'dart:async';
import 'package:flutter/material.dart';
import '../services/my_bluetooth_service.dart';

class AlertasPage extends StatefulWidget {
  final MyBluetoothService bluetooth;

  const AlertasPage({super.key, required this.bluetooth});

  @override
  State<AlertasPage> createState() => _AlertasPageState();
}

class _AlertasPageState extends State<AlertasPage> {
  final List<String> alertas = [];
  StreamSubscription<String>? _alertSub;

  @override
  void initState() {
    super.initState();

    // 🔥 Escucha mensajes interpretados del Bluetooth Classic
    _alertSub = widget.bluetooth.logController.stream.listen((mensaje) {
      if (mensaje.trim().isEmpty) return;

      final msg = mensaje.toLowerCase();

      // 🔔 Detectar alertas relevantes
      final esAlerta =
          msg.contains("movimiento") ||
          msg.contains("alerta") ||
          msg.contains("activado") ||
          msg.contains("gas") ||
          msg.contains("peligro");

      if (esAlerta) {
        final now = DateTime.now();
        final hora =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

        setState(() {
          alertas.insert(0, "$hora — $mensaje");
        });
      }
    });
  }

  @override
  void dispose() {
    _alertSub?.cancel(); // ❗ Evitar fugas de memoria
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alertas"),
        backgroundColor: Colors.orange,
      ),
      body: alertas.isEmpty
          ? const Center(
              child: Text(
                "No hay alertas registradas",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(15),
              itemCount: alertas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.red.shade50,
                  elevation: 3,
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: Text(
                      alertas[index],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
