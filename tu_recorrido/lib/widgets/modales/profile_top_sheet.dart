import 'package:flutter/material.dart';
import 'package:tu_recorrido/widgets/encabezados/user_profile_header.dart';

/// Hoja superior que muestra perfil y acciones rápidas
class ProfileTopSheet extends StatelessWidget {
  const ProfileTopSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const UserProfileHeader(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
