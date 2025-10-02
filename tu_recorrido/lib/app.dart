import 'package:flutter/material.dart';

// Screens
import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/registro.dart';

// AuthGate
import 'widgets/auth_gate.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recorrido',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4CAF50), // opcional
        brightness: Brightness.light,
      ),

      // Usamos AuthGate en la raíz: decide Home o Login según sesión
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthGate(
              signedIn: HomeScreen(),
              signedOut: LoginScreen(),
            ),
        '/home': (_) => const HomeScreen(),
        '/auth/login': (_) => const LoginScreen(),
        '/auth/registro': (_) => const RegistroScreen(),

        // Si ya tienes una pantalla de lugares, descomenta:
        // '/places': (_) => const PlacesScreen(),
      },
    );
  }
}