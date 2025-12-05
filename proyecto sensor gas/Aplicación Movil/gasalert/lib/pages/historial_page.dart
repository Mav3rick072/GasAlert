import 'dart:async';
import 'package:flutter/material.dart';
import '../services/my_bluetooth_service.dart';

class HistorialPage extends StatefulWidget {
  final MyBluetoothService bluetooth;

  const HistorialPage({super.key, required this.bluetooth});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  final List<String> logs = [];
  StreamSubscription<String>? _logSub;

  @override
  void initState() {
    super.initState();

    // 🔥 Escucha los mensajes interpretados del Bluetooth Classic
    _logSub = widget.bluetooth.logController.stream.listen((mensaje) {
      if (mensaje.trim().isEmpty) return;

      final now = DateTime.now();
      final hora =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      // 🔥 Guardar con hora
      setState(() {
        logs.insert(0, "$hora — $mensaje");
      });
    });
  }

  @override
  void dispose() {
    _logSub?.cancel(); // Evitar fugas de memoria
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial"),
        backgroundColor: Colors.orange,
      ),

      body: logs.isEmpty
          ? const Center(
              child: Text(
                "Sin registros aún",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(15),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text(
                      logs[index],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
