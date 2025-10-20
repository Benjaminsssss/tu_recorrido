import 'package:flutter/material.dart';
import '../models/place.dart';
import '../widgets/place_hero_card.dart';

/// Widget principal del feed vertical de lugares.
/// Reemplaza `mockPlaces` por tu fuente de datos remota cuando lo necesites.
class PlacesShowcase extends StatelessWidget {
  final List<Place> places;
  const PlacesShowcase({super.key, required this.places});

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return const Center(child: Text('No hay lugares disponibles.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: places.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: PlaceHeroCard(place: places[i]),
      ),
    );
  }
}
