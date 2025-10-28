import 'package:flutter/material.dart';
import '../components/bottom_nav_bar.dart';

/// Pantalla sencilla para la Colección / Álbum de usuario
class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  int _currentIndex = 1; // 0=Inicio,1=Colección,2=Mapa

  void _onNavChanged(int idx) {
    if (idx == 0) {
      // Volver al inicio (hacer pop hasta la primera ruta)
      if (Navigator.canPop(context)) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else if (idx == 2) {
      // Abrir mapa como antes
      Navigator.pushNamed(context, '/menu');
    } else {
      setState(() => _currentIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Colección'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex, onChanged: _onNavChanged),
    );
  }
}
