import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/my_bluetooth_service.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  final MyBluetoothService bt = MyBluetoothService();

  bool conectado = false;
  String estadoSensor = "Sin datos";
  StreamSubscription<bool>? _sensorSub;
  StreamSubscription<String>? _logSub;

  List<BluetoothDevice> dispositivos = [];
  bool escaneando = false;

  @override
  void initState() {
    super.initState();

    // Estado conectado/desconectado
    _sensorSub = bt.sensorController.stream.listen((activo) {
      setState(() => conectado = activo);
    });

    // Estado del sensor recibido desde el Arduino
    _logSub = bt.logController.stream.listen((log) {
      setState(() => estadoSensor = log);
    });
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _logSub?.cancel();
    super.dispose();
  }

  // ================================================================
  // 🔍 ESCANEAR (Bluetooth Classic = dispositivos emparejados)
  // ================================================================
  Future<void> _escanear() async {
    setState(() => escaneando = true);

    dispositivos = await bt.escanear();

    setState(() => escaneando = false);
  }

  // ================================================================
  // 🔌 CONECTAR A HC-05
  // ================================================================
  Future<void> _conectar(String nombre) async {
    try {
      await bt.conectar(nombre);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Conectado a $nombre")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al conectar: $e")));
    }
  }

  // ================================================================
  // 🔄 RECONEXIÓN MANUAL
  // ================================================================
  Future<void> _reconectar() async {
    await bt.desconectar();
    await Future.delayed(const Duration(seconds: 1));

    if (bt.ultimoId != null) {
      try {
        await bt.conectar("HC-05");
      } catch (_) {}
    }
  }

  // ================================================================
  // ❌ DESCONECTAR
  // ================================================================
  Future<void> _desconectar() async {
    await bt.desconectar();
    setState(() => conectado = false);
  }

  // ================================================================
  // UI
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio"),
        backgroundColor: Colors.orange,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              conectado ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: conectado ? Colors.blue : Colors.grey,
              size: 80,
            ),

            const SizedBox(height: 10),

            Text(
              conectado ? "Estado: Conectado" : "Estado: Desconectado",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: conectado ? Colors.green : Colors.red,
              ),
            ),

            const SizedBox(height: 20),

            Text("Sensor: $estadoSensor", style: const TextStyle(fontSize: 18)),

            const Divider(height: 40),

            // -----------------------------------------------------
            // 🔍 BOTON BUSCAR
            // -----------------------------------------------------
            ElevatedButton.icon(
              onPressed: escaneando ? null : _escanear,
              icon: const Icon(Icons.search),
              label: Text(escaneando ? "Buscando..." : "Buscar dispositivos"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // -----------------------------------------------------
            // 📋 LISTA DE DISPOSITIVOS EMPAREJADOS
            // -----------------------------------------------------
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dispositivos.length,
              itemBuilder: (context, index) {
                final d = dispositivos[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(d.name ?? "Sin nombre"),
                    subtitle: Text(d.address),
                    trailing: ElevatedButton(
                      onPressed: () => _conectar(d.name ?? "HC-05"),
                      child: const Text("Conectar"),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // -----------------------------------------------------
            // 🔄 RECONEXIÓN
            // -----------------------------------------------------
            ElevatedButton.icon(
              onPressed: conectado ? _reconectar : null,
              icon: const Icon(Icons.refresh),
              label: const Text("Reconectar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            // -----------------------------------------------------
            // ❌ DESCONECTAR
            // -----------------------------------------------------
            ElevatedButton.icon(
              onPressed: conectado ? _desconectar : null,
              icon: const Icon(Icons.close),
              label: const Text("Desconectar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
