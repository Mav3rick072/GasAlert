import 'package:flutter/material.dart';

class NuevaVentana extends StatelessWidget {
  const NuevaVentana({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Ventana'),
        backgroundColor: const Color(0xFFFF7B2B),
      ),
      body: const Center(
        child: Text(
          'Contenido de la nueva ventana',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
