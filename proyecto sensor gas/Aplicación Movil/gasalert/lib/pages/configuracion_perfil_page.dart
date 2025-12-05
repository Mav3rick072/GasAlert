import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class ConfiguracionPerfilPage extends StatefulWidget {
  const ConfiguracionPerfilPage({super.key});

  @override
  State<ConfiguracionPerfilPage> createState() =>
      _ConfiguracionPerfilPageState();
}

class _ConfiguracionPerfilPageState extends State<ConfiguracionPerfilPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  User? _usuario;
  Map<String, dynamic>? _datosUsuario;
  bool _editando = false;
  bool _cargando = true;
  bool _subiendoFoto = false;
  File? _imagenSeleccionada;
  late final AnimationController _bannerController;
  late final Animation<Offset> _bannerOffset;
  String _bannerMessage = '';

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _reautenticarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _bannerOffset = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _bannerController, curve: Curves.easeOut),
        );
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _reautenticarController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    _usuario = _auth.currentUser;

    if (_usuario != null) {
      try {
        final doc = await _firestore
            .collection('usuarios')
            .doc(_usuario!.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _datosUsuario = doc.data();
            _nombreController.text = _datosUsuario?['nombre'] ?? '';
            _correoController.text = _usuario!.email ?? '';
            _cargando = false;
          });
        } else {
          setState(() => _cargando = false);
        }
      } catch (e) {
        debugPrint("Error al cargar datos: $e");
        setState(() => _cargando = false);
      }
    } else {
      setState(() => _cargando = false);
    }
  }

  Future<void> _guardarCambios() async {
    if (_usuario == null) return;

    try {
      // Si se cambia correo o contraseña, pedimos reautenticación
      if (_correoController.text != _usuario!.email ||
          _passwordController.text.isNotEmpty) {
        final password = await _pedirReautenticacion();
        if (password == null) return; // Canceló el diálogo

        final cred = EmailAuthProvider.credential(
          email: _usuario!.email!,
          password: password,
        );

        await _usuario!.reauthenticateWithCredential(cred);
      }

      // Preparar cambios en Firestore
      final Map<String, dynamic> cambios = {};

      // Nombre
      if (_nombreController.text.trim().isNotEmpty) {
        cambios['nombre'] = _nombreController.text.trim();
        // Intentamos también actualizar el displayName en Firebase Auth
        try {
          await _usuario!.updateDisplayName(_nombreController.text.trim());
        } catch (_) {}
      }

      // Correo
      if (_correoController.text.trim().isNotEmpty &&
          _correoController.text.trim() != _usuario!.email) {
        cambios['email'] = _correoController.text.trim();
        // Enviar verificación para cambiar el correo en Auth
        try {
          await _usuario!.verifyBeforeUpdateEmail(
            _correoController.text.trim(),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Se envió un correo para verificar el nuevo email.',
                ),
              ),
            );
          }
        } catch (e) {
          // No bloqueamos el guardado en Firestore si falla el envío
          debugPrint('Error al solicitar verificación de email: $e');
        }
      }

      // Actualizar contraseña (si escribió algo)
      if (_passwordController.text.isNotEmpty) {
        await _usuario!.updatePassword(_passwordController.text);
      }

      // Aplicar cambios en Firestore si hay alguno
      if (cambios.isNotEmpty) {
        await _firestore
            .collection('usuarios')
            .doc(_usuario!.uid)
            .update(cambios);
        // Actualizar datos locales para reflejar los cambios inmediatamente
        setState(() {
          _datosUsuario ??= {};
          cambios.forEach((k, v) => _datosUsuario![k] = v);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados correctamente')),
        );
      }

      setState(() => _editando = false);

      // Mostrar banner animado y vibrar para dar feedback inmediato
      try {
        setState(() => _bannerMessage = 'Información del perfil actualizada');
        _bannerController.forward();
        HapticFeedback.vibrate();
      } catch (_) {}
      // Ocultar después de 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        _bannerController.reverse();
      });
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de autenticación: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar cambios: $e')));
      }
    }
  }

  Future<String?> _pedirReautenticacion() async {
    _reautenticarController.clear();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar identidad'),
        content: TextField(
          controller: _reautenticarController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Contraseña actual'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _reautenticarController.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // Nota: usamos _seleccionarFotoDesde para elegir cámara/galería desde el modal

  Future<void> _seleccionarFotoDesde(ImageSource source) async {
    try {
      final XFile? foto = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (foto != null) {
        setState(() => _imagenSeleccionada = File(foto.path));
        await _subirFotoPerfil();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo seleccionar la imagen: $e')),
        );
      }
    }
  }

  void _elegirFuenteFoto() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.of(context).pop();
                _seleccionarFotoDesde(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.of(context).pop();
                _seleccionarFotoDesde(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancelar'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _subirFotoPerfil() async {
    if (_imagenSeleccionada == null || _usuario == null) return;

    setState(() => _subiendoFoto = true);

    try {
      // Subir archivo a Firebase Storage
      final ref = _storage.ref().child('fotos_perfil/${_usuario!.uid}.jpg');
      await ref.putFile(_imagenSeleccionada!);

      // Obtener URL de descarga
      final urlFoto = await ref.getDownloadURL();

      // Actualizar URL en Firestore
      await _firestore.collection('usuarios').doc(_usuario!.uid).update({
        'fotoPerfil': urlFoto,
      });

      // Actualizar datos locales
      setState(() {
        _datosUsuario?['fotoPerfil'] = urlFoto;
        _imagenSeleccionada = null;
        _subiendoFoto = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada')),
        );
      }
    } catch (e) {
      setState(() => _subiendoFoto = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al subir foto: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_usuario == null) {
      return const Scaffold(
        body: Center(child: Text('No hay usuario autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Perfil'),
        backgroundColor: const Color(0xFFFF7B2B),
        actions: [
          IconButton(
            icon: Icon(_editando ? Icons.save : Icons.edit),
            onPressed: () {
              if (_editando) {
                _guardarCambios();
              } else {
                setState(() => _editando = true);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Banner animado (se desliza desde arriba)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SlideTransition(
              position: _bannerOffset,
              child: Container(
                color: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _bannerMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 🖼️ Foto de perfil
                  Stack(
                    children: [
                      _datosUsuario?['fotoPerfil'] != null
                          ? CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(
                                _datosUsuario!['fotoPerfil'],
                              ),
                            )
                          : const CircleAvatar(
                              radius: 50,
                              backgroundColor: Color(0xFFFF7B2B),
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                      if (_editando)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _subiendoFoto ? null : _elegirFuenteFoto,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF7B2B),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: _subiendoFoto
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _nombreController,
                    enabled: _editando,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _correoController,
                    enabled: _editando,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _passwordController,
                    enabled: _editando,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 25),

                  ElevatedButton(
                    onPressed: () async {
                      await _auth.signOut();
                      if (context.mounted) {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
