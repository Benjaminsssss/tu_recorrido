import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tu_recorrido/models/user_state.dart';

/// Muestra [signedIn] si el usuario está autenticado (según `UserState`),
/// en caso contrario muestra [signedOut].
class AuthGate extends StatelessWidget {
  final Widget signedIn;
  final Widget signedOut;

  const AuthGate({super.key, required this.signedIn, required this.signedOut});

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    // `UserState` se provee mediante Provider y no es nulo en tiempo de ejecución.
    return userState.isAuthenticated ? signedIn : signedOut;
  }
}
