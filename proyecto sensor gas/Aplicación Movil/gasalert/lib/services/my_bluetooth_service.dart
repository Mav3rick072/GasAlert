import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'notification_service.dart';

class MyBluetoothService {
  BluetoothConnection? _connection;
  BluetoothDevice? dispositivoActual;

  final StreamController<bool> sensorController =
      StreamController<bool>.broadcast();
  final StreamController<String> logController =
      StreamController<String>.broadcast();

  String? ultimoId;
  bool intentandoReconectar = false;

  // 🔍 ESCANEAR DISPOSITIVOS
  Future<List<BluetoothDevice>> escanear() async {
    await FlutterBluetoothSerial.instance.requestEnable();
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  // 🔌 CONECTAR A HC-05
  Future<void> conectar(String nombre) async {
    await FlutterBluetoothSerial.instance.requestEnable();

    List<BluetoothDevice> paired = await FlutterBluetoothSerial.instance
        .getBondedDevices();

    // Buscar el dispositivo por nombre
    BluetoothDevice? device;
    final encontrados = paired.where((d) => d.name == nombre);

    if (encontrados.isNotEmpty) {
      device = encontrados.first;
    } else {
      throw "No se encontró el dispositivo $nombre";
    }

    dispositivoActual = device;
    ultimoId = device.address;

    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      sensorController.add(true);

      NotificationService.showNotification(
        "Conectado",
        "HC-05 conectado correctamente",
      );

      _escucharDatos();
    } catch (e) {
      sensorController.add(false);
      rethrow;
    }
  }

  // 📡 ESCUCHAR DATOS
  void _escucharDatos() {
    if (_connection == null) return;

    _connection!.input!.listen(
      (data) {
        String recibido = utf8.decode(data).trim();
        String mensaje = interpretarDato(recibido);
        logController.add(mensaje);

        NotificationService.showNotification("Alerta del sensor", mensaje);
      },
      onDone: () {
        sensorController.add(false);
        NotificationService.showNotification(
          "Desconectado",
          "Intentando reconectar...",
        );
        _intentarReconectar();
      },
      onError: (_) {
        sensorController.add(false);
        _intentarReconectar();
      },
      cancelOnError: true,
    );
  }

  // 🔄 RECONEXIÓN AUTOMÁTICA
  Future<void> _intentarReconectar() async {
    if (intentandoReconectar || ultimoId == null) return;

    intentandoReconectar = true;
    await Future.delayed(const Duration(seconds: 2));

    try {
      _connection = await BluetoothConnection.toAddress(ultimoId!);
      sensorController.add(true);
      NotificationService.showNotification(
        "Reconectado",
        "Conexión restablecida con HC-05",
      );
      _escucharDatos();
    } catch (_) {}
    intentandoReconectar = false;
  }

  // 🔠 INTERPRETAR DATOS DEL SENSOR
  String interpretarDato(String valor) {
    switch (valor) {
      case "1":
        return "Movimiento detectado";
      case "0":
        return "Sin movimiento";
      case "A":
        return "Sensor activado";
      case "B":
        return "Sensor desactivado";
      default:
        return "Dato recibido: $valor";
    }
  }

  // 📤 ENVIAR DATOS
  Future<void> enviar(String texto) async {
    if (_connection != null && _connection!.isConnected) {
      _connection!.output.add(utf8.encode(texto));
      await _connection!.output.allSent;
    }
  }

  // ❌ DESCONECTAR
  Future<void> desconectar() async {
    try {
      await _connection?.close();
    } catch (_) {}
    sensorController.add(false);
  }
}
