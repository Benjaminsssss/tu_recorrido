import 'package:flutter/material.dart';

/// Ejemplo simple para mostrar un álbum de fotos (placeholder)
class AlbumPhotosExample extends StatelessWidget {
  final List<String> images;

  const AlbumPhotosExample({super.key, this.images = const []});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const Center(child: Text('No hay fotos en el álbum'));
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(images[index], width: 160, fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}
