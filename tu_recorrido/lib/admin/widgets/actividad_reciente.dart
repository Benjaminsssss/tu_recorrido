import 'dart:async';

import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tu_recorrido/utils/theme/colores.dart';

class ActividadRecienteWidget extends StatefulWidget {
  const ActividadRecienteWidget({super.key});

  @override
  State<ActividadRecienteWidget> createState() =>
      _ActividadRecienteWidgetState();
}

class _ActividadRecienteWidgetState extends State<ActividadRecienteWidget> {
  late StreamController<List<Map<String, dynamic>>> _controller;
  late StreamZip _zip;

  @override
  void initState() {
    super.initState();
    _controller = StreamController.broadcast();
    _zip = StreamZip([
      FirebaseFirestore.instance
          .collection('estaciones')
          .orderBy('fechaCreacion', descending: true)
          .limit(8)
          .snapshots(),
      FirebaseFirestore.instance
          .collection('insignias')
          .orderBy('fechaCreacion', descending: true)
          .limit(8)
          .snapshots(),
    ]);

    _zip.listen((snapshots) {
      final List<Map<String, dynamic>> items = [];

      for (int i = 0; i < snapshots.length; i++) {
        final s = snapshots[i];
        if (s is QuerySnapshot) {
          for (final doc in s.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final when = (data['fechaCreacion'] as Timestamp?) ??
                (data['createdAt'] as Timestamp?);
            // Determine type by index: 0 -> estaciones, 1 -> insignias
            final isEstacion = i == 0;
            items.add({
              'when': when?.toDate() ?? DateTime.now(),
              'title': isEstacion
                  ? 'Nueva estación creada'
                  : 'Nueva insignia creada',
              'subtitle': isEstacion
                  ? (data['nombre'] ?? '')
                  : (data['nombre'] ?? data['title'] ?? ''),
              'color': isEstacion
                  ? Coloressito.adventureGreen
                  : Coloressito.badgeYellow,
              'icon': isEstacion ? Icons.location_on : Icons.emoji_events,
            });
          }
        }
      }

      items.sort(
          (a, b) => (b['when'] as DateTime).compareTo(a['when'] as DateTime));
      _controller.add(items);
    });
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Coloressito.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actividad reciente',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _controller.stream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data!;
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (context, index) {
                    final it = items[index];
                    return ListTile(
                      leading: CircleAvatar(
                          backgroundColor: it['color'] as Color,
                          child: Icon(it['icon'] as IconData,
                              color: Colors.white, size: 18)),
                      title: Text(it['title'] as String),
                      subtitle: Text(it['subtitle'] as String),
                      trailing: Text(_formatDate(it['when'] as DateTime)),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${d.day}/${d.month}/${d.year}';
  }
}
