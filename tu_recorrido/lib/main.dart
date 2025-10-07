import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'firebase_options_dev.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con tus opciones DEV
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Manejo global de errores
  runZonedGuarded(
    () {
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.dumpErrorToConsole(details);
      };
      runApp(const MyApp());
    },
    (error, stack) {
      debugPrint('❌ Uncaught error: $error\n$stack');
    },
  );
}
