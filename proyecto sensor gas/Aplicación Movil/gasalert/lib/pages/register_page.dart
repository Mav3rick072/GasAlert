import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'email_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = false;

  /// Validar contraseña fuerte
  bool _isValidPassword(String password) {
    final hasMinLength = password.length >= 8;
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    return hasMinLength && hasNumber && hasUppercase;
  }

  Future<void> _register() async {
    if (_loading) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Complete todos los campos');
      return;
    }

    if (!_isValidPassword(password)) {
      _showMessage(
        'La contraseña debe tener mínimo 8 caracteres,\n'
        'al menos 1 número y 1 mayúscula.',
      );
      return;
    }

    try {
      setState(() => _loading = true);

      // Crear usuario en Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User user = credential.user!;

      // Guardar datos en Firestore
      await _firestore.collection('usuarios').doc(user.uid).set({
        'nombre': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Enviar el correo de verificación
      await user.sendEmailVerification();

      _showMessage('¡Registro exitoso! Revisa tu correo', success: true);

      // Redirigir a pantalla de verificación
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationPage(user: user),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Ocurrió un error';

      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Este correo ya está registrado';
          break;

        case 'weak-password':
          msg = 'La contraseña es demasiado débil';
          break;

        case 'invalid-email':
          msg = 'El correo no es válido';
          break;
      }

      _showMessage(msg);
    } catch (e) {
      _showMessage("Error inesperado: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showMessage(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(
                  Icons.gas_meter,
                  size: 100,
                  color: Color(0xFFFF7B2B),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Crear cuenta",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF7B2B),
                  ),
                ),
                const SizedBox(height: 40),

                // Nombre
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Email
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Botón registrar
                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7B2B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 60,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Registrarse',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
