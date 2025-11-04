import 'package:flutter/material.dart';
import '../services/debug_auth_service.dart';
import '../services/album_migration_service.dart';

class DebugAuthScreen extends StatefulWidget {
  const DebugAuthScreen({super.key});

  @override
  State<DebugAuthScreen> createState() => _DebugAuthScreenState();
}

class _DebugAuthScreenState extends State<DebugAuthScreen> {
  String _diagnosisResult = 'Presiona un botón para ejecutar el diagnóstico...';
  bool _isRunning = false;

  Future<void> _runAuthDiagnosis() async {
    if (_isRunning) return;
    
    setState(() {
      _isRunning = true;
      _diagnosisResult = 'Ejecutando diagnóstico de autenticación...';
    });

    try {
      final diagnosis = await DebugAuthService.diagnoseAuth();
      final formattedResult = DebugAuthService.formatDiagnosis(diagnosis);
      
      setState(() {
        _diagnosisResult = formattedResult;
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _diagnosisResult = 'Error durante el diagnóstico de auth: $e';
        _isRunning = false;
      });
    }
  }

  Future<void> _runAlbumDiagnosis() async {
    if (_isRunning) return;
    
    setState(() {
      _isRunning = true;
      _diagnosisResult = 'Ejecutando diagnóstico del álbum...';
    });

    try {
      final diagnosis = await AlbumMigrationService.diagnoseAlbum();
      final formattedResult = AlbumMigrationService.formatDiagnosis(diagnosis);
      
      setState(() {
        _diagnosisResult = formattedResult;
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _diagnosisResult = 'Error durante el diagnóstico del álbum: $e';
        _isRunning = false;
      });
    }
  }

  Future<void> _migratePhotos() async {
    if (_isRunning) return;
    
    // Confirmar migración
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar migración'),
        content: const Text(
          '¿Estás seguro de que quieres migrar las fotos de SharedPreferences a Firebase? '
          'Esta operación puede tardar unos minutos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Migrar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    
    setState(() {
      _isRunning = true;
      _diagnosisResult = 'Migrando fotos a Firebase...';
    });

    try {
      final result = await AlbumMigrationService.migratePhotosToFirebase();
      final formattedResult = AlbumMigrationService.formatMigrationResult(result);
      
      setState(() {
        _diagnosisResult = formattedResult;
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _diagnosisResult = 'Error durante la migración: $e';
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico de Autenticación'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _runAuthDiagnosis,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: _isRunning
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Ejecutando...'),
                      ],
                    )
                  : const Text(
                      'Diagnóstico de Autenticación',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isRunning ? null : _runAlbumDiagnosis,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Diagnóstico del Álbum',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isRunning ? null : _migratePhotos,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Migrar Fotos a Firebase',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _diagnosisResult,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}