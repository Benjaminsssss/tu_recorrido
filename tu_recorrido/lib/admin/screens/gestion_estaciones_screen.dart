import 'package:flutter/material.dart';
import '../../widgets/pantalla_base.dart';
import '../../widgets/role_protected_widget.dart';
import '../widgets/estaciones_table.dart';

/// Nueva pantalla que contiene la tabla de gestión de estaciones
class GestionEstacionesScreen extends StatelessWidget {
  const GestionEstacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminProtectedWidget(
      child: PantallaBase(
        titulo: 'Gestión de Estaciones',
        backgroundColor: Colors.white,
        appBarBackgroundColor: Colors.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const EstacionesTable(key: Key('estaciones_table')),
          ],
        ),
      ),
    );
  }
}
