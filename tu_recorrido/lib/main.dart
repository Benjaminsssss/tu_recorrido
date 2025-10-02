import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'firebase_options_dev.dart'; // 👈 tu archivo de opciones (DEV)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con tus opciones DEV
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Manejo global de errores (útil en desarrollo)
  runZonedGuarded(() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
    };
    runApp(const MyApp());
  }, (error, stack) {
    // ignore: avoid_print
    print('❌ Uncaught error: $error\n$stack');
  });
}




