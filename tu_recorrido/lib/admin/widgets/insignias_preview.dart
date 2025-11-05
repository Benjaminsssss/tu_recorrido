import 'package:flutter/material.dart';

import '../../models/insignia.dart';
import '../../utils/colores.dart';

class InsigniasPreview extends StatelessWidget {
  final List<Insignia> insignias;

  const InsigniasPreview({super.key, required this.insignias});

  @override
  Widget build(BuildContext context) {
    if (insignias.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Coloressito.borderLight)),
        child: const Center(child: Text('No hay insignias aún')),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: insignias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final ins = insignias[index];
          return Container(
            width: 150,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Coloressito.borderLight)),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ins.imagenUrl.isNotEmpty
                        ? Image.network(ins.imagenUrl,
                            fit: BoxFit.cover, width: double.infinity)
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                                child: Icon(Icons.emoji_events,
                                    size: 34, color: Colors.grey))),
                  ),
                ),
                const SizedBox(height: 6),
                Text(ins.nombre,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }
}
