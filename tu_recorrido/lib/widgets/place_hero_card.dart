import 'package:flutter/material.dart';
import '../models/place.dart';
import 'badge_pill.dart';
import 'image_carousel.dart';
import 'place_modal.dart';

class PlaceHeroCard extends StatelessWidget {
  final Place place;
  const PlaceHeroCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(28),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: ImageCarousel(images: place.imagenes),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    place.nombre,
                    style: const TextStyle(
                      fontFamily: 'Pacifico',
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                      color: Colors.black87,
                    ),
                  ),
                ),
                BadgePill(badge: place.badge),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) {
                        return AnimatedPadding(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: FractionallySizedBox(
                            heightFactor: 0.92,
                            child: Material(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                              child: PlaceModal(place: place),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('Ver detalles'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
