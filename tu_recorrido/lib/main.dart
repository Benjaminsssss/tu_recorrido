import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/registro.dart';
import 'screens/login.dart';
import 'screens/menu.dart';
import 'screens/home.dart';
import 'screens/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "tu-api-key-aqui", // Reemplazar con tu API key
      authDomain: "tu-proyecto.firebaseapp.com",
      projectId: "tu-proyecto-id",
      storageBucket: "tu-proyecto.appspot.com",
      messagingSenderId: "123456789",
      appId: "1:123456789:web:abcdef123456",
    ),
  );
  
  if (kIsWeb) {
    // Usa URLs sin hash para que se vea como https://app.recorrido.org/
    usePathUrlStrategy();
  }
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recorrido',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/registro': (_) => const RegistroScreen(),
        '/auth': (_) => const AuthScreen(),
        '/auth/login': (_) => const AuthScreen(isLogin: true),
        '/menu': (_) => Mapita(),
      },
    );
  }
}



