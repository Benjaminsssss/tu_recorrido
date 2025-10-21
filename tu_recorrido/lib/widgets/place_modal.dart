import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/place.dart';
import '../services/saved_places_service.dart';

class PlaceModal extends StatefulWidget {
  final Place place;
  const PlaceModal({super.key, required this.place});

  @override
  State<PlaceModal> createState() => _PlaceModalState();
}

class _PlaceModalState extends State<PlaceModal> {
  bool _isSaved = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isSaved =
          await SavedPlacesService.isPlaceSaved(user.uid, widget.place.id);
      if (mounted) {
        setState(() {
          _isSaved = isSaved;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes iniciar sesión para guardar lugares'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSaved) {
        await SavedPlacesService.removePlaceForUser(user.uid, widget.place.id);
        if (mounted) {
          setState(() {
            _isSaved = false;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.place.nombre} eliminado de favoritos'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        await SavedPlacesService.savePlaceForUser(user.uid, widget.place.id);
        if (mounted) {
          setState(() {
            _isSaved = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.place.nombre} guardado en favoritos'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar. Intenta de nuevo.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

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
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image(
                    image: widget.place.imagenes.first.imageProvider(),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    semanticLabel: widget.place.imagenes.first.alt,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Nombre del lugar centrado
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  widget.place.nombre,
                  style: const TextStyle(
                    fontFamily: 'Pacifico',
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Descripción a la izquierda + Ícono bookmark a la derecha
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Descripción expandida a la izquierda
                    Expanded(
                      child: Text(
                        widget.place.descripcion,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Ícono de bookmark/guardar a la derecha
                    Container(
                      decoration: BoxDecoration(
                        color: _isSaved
                            ? const Color(0xFFE3F2FD)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                _isSaved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                size: 28,
                              ),
                              color: _isSaved
                                  ? const Color(0xFF2B6B7F)
                                  : Colors.black54,
                              onPressed: _toggleSave,
                            ),
                    ),
                  ],
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
