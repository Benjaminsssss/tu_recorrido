import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user_state.dart';

class UserStateProvider extends StatelessWidget {
  final Widget child;
  final String nombre;
  final String? avatarUrl;

  const UserStateProvider({
    super.key,
    required this.child,
    required this.nombre,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserState(nombre: nombre, avatarUrl: avatarUrl),
      child: child,
    );
  }
}
