import 'package:flutter/material.dart';
import '../services/insignia_service.dart';

/// Script temporal para migrar insignias existentes
class MigrationScript extends StatelessWidget {
  const MigrationScript({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Migración de Insignias'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ejecutar migración de insignias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Esto actualizará todas las estaciones que tienen insignias\n'
              'asignadas pero no tienen el campo badgeImage.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Mostrar indicador de carga
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Ejecutando migración...'),
                        ],
                      ),
                    ),
                  );

                  // Ejecutar la migración
                  await InsigniaService.migrarInsigniasExistentes();

                  // Cerrar el dialog de carga
                  if (context.mounted) Navigator.of(context).pop();

                  // Mostrar mensaje de éxito
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Migración completada exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // Cerrar el dialog de carga
                  if (context.mounted) Navigator.of(context).pop();

                  // Mostrar error
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error en migración: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Ejecutar Migración'),
            ),
          ],
        ),
      ),
    );
  }
}