import '../models/place.dart';

// Lista mock de lugares. Puedes reemplazar esto por una llamada a API en el futuro.
final List<Place> mockPlaces = [
  Place(
    id: 'cerro-san-cristobal',
    nombre: 'Cerro San Cristóbal',
    region: 'Chile',
    comuna: 'Providencia/Recoleta',
    shortDesc: 'Miradores icónicos, teleférico y atardeceres de postal.',
    descripcion:
        'El parque urbano más grande de Chile. Sube en teleférico o funicular, disfruta de vistas 360° de la ciudad y visita la imagen de la Inmaculada Concepción.',
    mejorMomento: 'Tarde–atardecer.',
    badge: PlaceBadge(nombre: 'Vigilante de la Ciudad', tema: 'Naturaleza'),
    imagenes: [
      PlaceImage(
        url:
            'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
        alt: 'Vista panorámica de Santiago desde el Cerro San Cristóbal',
      ),
      PlaceImage(
        url:
            'https://images.unsplash.com/photo-1464983953574-0892a716854b?auto=format&fit=crop&w=800&q=80',
        alt: 'Cabinas del teleférico sobre áreas verdes',
      ),
    ],
  ),
  // ...agrega aquí los otros 9 lugares siguiendo el mismo formato...
];
