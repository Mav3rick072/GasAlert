import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'configuracion_perfil_page.dart';
import 'dart:async';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  bool sensorConectado =
      true; // Simulación (más adelante puedes vincularlo al sensor real)
  bool alertaUrgente = false; // Simulación
  String nombreUsuario = "Cargando...";

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    User? usuario = _auth.currentUser;
    if (usuario != null) {
      // Escuchar en tiempo real los cambios del documento del usuario
      try {
        _userSub = _firestore
            .collection('usuarios')
            .doc(usuario.uid)
            .snapshots()
            .listen(
              (doc) {
                if (doc.exists) {
                  final data = doc.data();
                  setState(() {
                    nombreUsuario =
                        data?['nombre'] ?? usuario.email ?? 'Usuario';
                  });
                } else {
                  setState(() {
                    nombreUsuario = usuario.email ?? 'Usuario';
                  });
                }
              },
              onError: (e) {
                debugPrint('Error al escuchar usuario: $e');
              },
            );
      } catch (e) {
        setState(() {
          nombreUsuario = 'Error al cargar usuario';
        });
        debugPrint("Error al obtener datos del usuario: $e");
      }
    } else {
      setState(() {
        nombreUsuario = 'Invitado';
      });
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🧭 Título principal
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF7B2B),
                ),
              ),
              const SizedBox(height: 30),

              // 🔌 Estado del sensor
              Row(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.gas_meter,
                      size: 60,
                      color: Color(0xFFFF7B2B),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sensor principal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        sensorConectado ? 'Conectado' : 'Desconectado',
                        style: TextStyle(
                          fontSize: 16,
                          color: sensorConectado ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 🚨 Alerta urgente
              alertaUrgente
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.red[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'ALERTA URGENTE: Gas detectado 🚨',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Todo en orden ✅',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
              const SizedBox(height: 30),

              // 👤 Perfil del usuario
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConfiguracionPerfilPage(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        nombreUsuario,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
