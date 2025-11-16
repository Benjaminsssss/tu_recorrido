// ignore_for_file: unnecessary_type_check

import 'package:flutter/material.dart';
import 'package:tu_recorrido/models/estacion.dart';
import 'package:tu_recorrido/models/place.dart';
import 'package:tu_recorrido/models/estacion_visitada.dart';
import 'package:tu_recorrido/widgets/insignias/place_hero_card.dart';

/// Lista de estaciones sencilla que reutiliza `PlaceHeroCard` para cada item
class ListaEstaciones extends StatelessWidget {
  final List<dynamic> estaciones;
  final void Function(dynamic)? onTap;

  const ListaEstaciones({super.key, required this.estaciones, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (estaciones.isEmpty) {
      return const Center(child: Text('No hay estaciones'));
    }

    return ListView.separated(
      itemCount: estaciones.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = estaciones[index];

        // Mapear distintos tipos (Estacion o EstacionVisitada) a Place
        // algunos callsites pasan listas homogéneas; silenciamos linter puntual
        Place place;
        if (item is EstacionVisitada) {
          final ev = item;
          place = Place(
            id: ev.estacionId,
            nombre: ev.estacionNombre,
            region: 'Chile',
            comuna: '',
            shortDesc: '',
            descripcion: '',
            mejorMomento: '',
            badge: PlaceBadge(nombre: 'Insignia', tema: 'Cultura'),
            imagenes: ev.badgeImage != null ? [ev.badgeImage!] : [],
          );
        } else if (item is Estacion) {
          place = Place(
            id: item.id,
            nombre: item.nombre,
            region: 'Chile',
            comuna: item.comuna ?? '',
            shortDesc: item.descripcion.length > 80 ? item.descripcion.substring(0, 80) : item.descripcion,
            descripcion: item.descripcion,
            mejorMomento: '',
            badge: PlaceBadge(nombre: 'Insignia', tema: 'Cultura'),
            imagenes: item.imagenes.map((m) {
              if (m is Map<String, dynamic>) return PlaceImage.fromJson(m);
              return PlaceImage(url: null, path: null, base64: null, alt: '');
            }).toList(),
          );
        } else {
          place = Place(
            id: 'unknown',
            nombre: item.toString(),
            region: '',
            comuna: '',
            shortDesc: '',
            descripcion: '',
            mejorMomento: '',
            badge: PlaceBadge(nombre: 'Insignia', tema: 'Cultura'),
            imagenes: [],
          );
        }

        return InkWell(
          onTap: onTap == null ? null : () => onTap!(item),
          child: PlaceHeroCard(place: place),
        );
      },
    );
  }
}
