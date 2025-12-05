import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart'; // Para navegar al Dashboard después de verificar
import 'login_page.dart';

class EmailVerificationPage extends StatefulWidget {
  final User user;

  const EmailVerificationPage({super.key, required this.user});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  late Timer _checkTimer;
  late Timer _timeoutTimer;

  @override
  void initState() {
    super.initState();

    // Revisar cada 3 segundos si el usuario ya verificó su correo
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await widget.user.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        _checkTimer.cancel();
        _timeoutTimer.cancel();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    });

    // Tiempo máximo de espera → 15 minutos
    _timeoutTimer = Timer(const Duration(minutes: 15), () async {
      _checkTimer.cancel();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No verificaste tu correo en 15 minutos. Intenta de nuevo.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _checkTimer.cancel();
    _timeoutTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.email_rounded,
                size: 120,
                color: Color(0xFFFF7B2B),
              ),
              const SizedBox(height: 25),
              const Text(
                "Verifica tu correo",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF7B2B),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "Te enviamos un correo a:\n${widget.user.email}\n\n"
                "Cuando lo confirmes podrás continuar.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(color: Color(0xFFFF7B2B)),
              const SizedBox(height: 20),
              const Text(
                "Esperando verificación...",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
