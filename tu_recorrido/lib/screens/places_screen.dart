import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tu_recorrido/services/infra/firestore_service.dart';

class PlacesScreen extends StatelessWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lugares')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService.instance.watchEstaciones(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No hay lugares aún'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final id = docs[i].id;
              final d = docs[i].data();
              final name = d['nombre'] ?? d['name'] ?? '—';
              final category = d['category'] ?? '—';
              final lat = d['lat'];
              final lng = d['lng'];

              return ListTile(
                title: Text(name),
                subtitle: Text('$category  •  $lat, $lng'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Eliminar lugar'),
                        content: Text('¿Eliminar "$name"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await FirestoreService.instance.deleteEstacion(id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlaceDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddPlaceDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'general');
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Nuevo lugar'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: catCtrl,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                ),
                TextFormField(
                  controller: latCtrl,
                  decoration: const InputDecoration(labelText: 'Latitud'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'Número válido' : null,
                ),
                TextFormField(
                  controller: lngCtrl,
                  decoration: const InputDecoration(labelText: 'Longitud'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'Número válido' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await FirestoreService.instance.createEstacion(
                nombre: nameCtrl.text.trim(),
                category: catCtrl.text.trim(),
                lat: double.parse(latCtrl.text),
                lng: double.parse(lngCtrl.text),
              );
              if (c.mounted) Navigator.pop(c);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
