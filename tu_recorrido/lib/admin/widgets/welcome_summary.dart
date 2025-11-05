import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/colores.dart';

/// Welcome summary styled like the provided example.
/// Shows three live metrics: Estaciones, Usuarios, Insignias with small delta text.
class WelcomeSummary extends StatelessWidget {
  const WelcomeSummary({super.key});

  Future<Map<String, int>> _computeDeltas(
      String collection, String dateField) async {
    final now = DateTime.now();
    final last30 = now.subtract(const Duration(days: 30));
    final prev30 = now.subtract(const Duration(days: 60));

    try {
      final totalSnap =
          await FirebaseFirestore.instance.collection(collection).get();
      final lastSnap = await FirebaseFirestore.instance
          .collection(collection)
          .where(dateField, isGreaterThanOrEqualTo: Timestamp.fromDate(last30))
          .get();
      final prevSnap = await FirebaseFirestore.instance
          .collection(collection)
          .where(dateField, isGreaterThanOrEqualTo: Timestamp.fromDate(prev30))
          .where(dateField, isLessThan: Timestamp.fromDate(last30))
          .get();

      return {
        'total': totalSnap.docs.length,
        'last': lastSnap.docs.length,
        'prev': prevSnap.docs.length,
      };
    } catch (e) {
      // Fallback: if dateField not present or query fails, return zeros
      return {'total': 0, 'last': 0, 'prev': 0};
    }
  }

  Widget _metricCard(
      {required String title,
      required IconData icon,
      required Color color,
      required Stream<QuerySnapshot> stream,
      required Future<Map<String, int>> Function() deltaFuture}) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        final total = snap.hasData ? snap.data!.docs.length : 0;
        return FutureBuilder<Map<String, int>>(
          future: deltaFuture(),
          builder: (context, dsnap) {
            final last = dsnap.hasData ? dsnap.data!['last'] ?? 0 : 0;
            final prev = dsnap.hasData ? dsnap.data!['prev'] ?? 0 : 0;
            final delta = last - prev;
            final deltaText =
                delta >= 0 ? '+$delta este mes' : '$delta este mes';

            return Container(
              width: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Coloressito.borderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 12)),
                        const SizedBox(height: 8),
                        Text(total.toString(),
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color)),
                        const SizedBox(height: 6),
                        Text(deltaText,
                            style: const TextStyle(
                                color: Colors.green, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: color.withAlpha((0.12 * 255).round()),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: color),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Coloressito.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¡Bienvenido al Panel de Administración!',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Aquí tienes un resumen de la actividad de la plataforma',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          Row(
            children: [
              _metricCard(
                title: 'Total Estaciones',
                icon: Icons.location_city,
                color: Coloressito.adventureGreen,
                stream: FirebaseFirestore.instance
                    .collection('estaciones')
                    .snapshots(),
                deltaFuture: () =>
                    _computeDeltas('estaciones', 'fechaCreacion'),
              ),
              const SizedBox(width: 12),
              _metricCard(
                title: 'Usuarios Activos',
                icon: Icons.people,
                color: Coloressito.badgeBlue,
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                // try with createdAt field for users
                deltaFuture: () => _computeDeltas('users', 'createdAt'),
              ),
              const SizedBox(width: 12),
              _metricCard(
                title: 'Insignias',
                icon: Icons.emoji_events,
                color: Coloressito.badgeYellow,
                stream: FirebaseFirestore.instance
                    .collection('insignias')
                    .snapshots(),
                deltaFuture: () => _computeDeltas('insignias', 'fechaCreacion'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
