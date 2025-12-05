import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../services/my_bluetooth_service.dart';
import 'pages/inicio_page.dart';
import 'pages/alertas_page.dart';
import 'pages/historial_page.dart';
import 'pages/login_page.dart';
import 'pages/splash_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gas Alert',
      theme: ThemeData(
        primaryColor: const Color(0xFFFF7B2B),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showingSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showingSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showingSplash) {
      return SplashScreen(
        nextPage: const AuthPage(),
        duration: const Duration(seconds: 0),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return const DashboardScreen();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return const DashboardScreen();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

// -----------------------------
// DASHBOARD CON BLUETOOTH GLOBAL
// -----------------------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final MyBluetoothService bluetooth =
      MyBluetoothService(); // ⭐ Instancia global

  int _selectedIndex = 0;
  DateTime? _backgroundEnteredAt;
  final Duration _logoutTimeout = const Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundEnteredAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundEnteredAt != null) {
        final elapsed = DateTime.now().difference(_backgroundEnteredAt!);
        if (elapsed >= _logoutTimeout) {
          FirebaseAuth.instance.signOut();
        }
        _backgroundEnteredAt = null;
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      InicioPage(),
      AlertasPage(bluetooth: bluetooth),
      HistorialPage(bluetooth: bluetooth),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gas Alert', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF7B2B),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: const Color(0xFFFF7B2B),
        selectedItemColor: Colors.orange[800],
        unselectedItemColor: Colors.orange[400],
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Alertas'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}
