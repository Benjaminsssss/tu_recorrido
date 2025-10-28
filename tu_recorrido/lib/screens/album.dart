import 'package:flutter/material.dart';

/// Pantalla sencilla para la Colección / Álbum de usuario
class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Colección'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.photo_album, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Tu álbum está vacío',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            SizedBox(height: 8),
            Text(
              'Aquí aparecerán las estaciones que guardes o desbloquees.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}
