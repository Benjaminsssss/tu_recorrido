import 'package:flutter/material.dart';
import '../models/place.dart';

class PlaceModal extends StatelessWidget {
  final Place place;
  const PlaceModal({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta != null && details.primaryDelta! < -18) {
          Navigator.of(context).pop();
        }
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 16/9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image(
                    image: place.imagenes.first.imageProvider(),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    semanticLabel: place.imagenes.first.alt,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                place.nombre,
                style: const TextStyle(
                  fontFamily: 'Pacifico',
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  place.descripcion,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // Barrita arriba para cerrar el modal
            ],
          ),
        ),
      ),
    );
  }
}
