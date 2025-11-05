import 'package:flutter/material.dart';
import '../../models/estacion.dart';
import '../../services/estacion_service.dart';
import '../../utils/colores.dart';
import '../screens/crear_estacion.dart';
import 'estacion_image_manager_dialog.dart';

class EstacionesTable extends StatefulWidget {
  const EstacionesTable({super.key});

  @override
  State<EstacionesTable> createState() => _EstacionesTableState();
}

class _EstacionesTableState extends State<EstacionesTable> {
  bool _loading = true;
  List<Estacion> _estaciones = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await EstacionService.obtenerEstacionesActivas();
      if (mounted) setState(() => _estaciones = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar estaciones: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showEditDialog(Estacion est) async {
    final nombreCtrl = TextEditingController(text: est.nombre);
    final descCtrl = TextEditingController(text: est.descripcion);
    final comunaCtrl = TextEditingController(text: est.comuna ?? '');

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar estación'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
              TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
              TextFormField(controller: comunaCtrl, decoration: const InputDecoration(labelText: 'Comuna')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Coloressito.adventureGreen),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final updated = est.copyWith(nombre: nombreCtrl.text.trim(), descripcion: descCtrl.text.trim(), comuna: comunaCtrl.text.trim());
                try {
                  await EstacionService.actualizarEstacion(est.id, updated);
                  if (mounted) Navigator.of(ctx).pop(true);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
                }
              },
              child: const Text('Guardar'))
        ],
      ),
    );

    if (result == true) await _load();
  }

  Future<void> _confirmDeactivate(Estacion est) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Desactivar la estación "${est.nombre}"? Esta acción la ocultará del sistema.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), style: ElevatedButton.styleFrom(backgroundColor: Coloressito.badgeRed), child: const Text('Desactivar'))
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await EstacionService.desactivarEstacion(est.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estación desactivada')));
        await _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al desactivar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // subtle off-white to make the card stand out from pure white backgrounds
        color: const Color(0xFFFBFCFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Coloressito.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_city),
              const SizedBox(width: 8),
              Text('Gestión de Estaciones', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Coloressito.adventureGreen),
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CrearEstacionScreen()));
                  await _load();
                },
                icon: const Icon(Icons.add),
                label: const Text('Crear'),
              )
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                // make header row slightly grey and increase spacing so the table reads better
                headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                headingTextStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                dataRowHeight: 64,
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Descripción')),
                  DataColumn(label: Text('Comuna')),
                  DataColumn(label: Text('Imagen')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: _estaciones.map((e) {
                final imageUrl = e.imagenes.isNotEmpty ? (e.imagenes[0]['url']?.toString() ?? '') : '';
                return DataRow(cells: [
                  DataCell(SizedBox(width: 200, child: Text(e.nombre, overflow: TextOverflow.ellipsis))),
                  DataCell(SizedBox(width: 300, child: Text(e.descripcion, overflow: TextOverflow.ellipsis))),
                  DataCell(Text(e.comuna ?? '-')),
                  DataCell(
                    imageUrl.isNotEmpty
                        ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(imageUrl, width: 80, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 80, height: 48, color: Colors.grey)))
                        : Container(width: 80, height: 48, decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200))),
                  ),
                  DataCell(Row(children: [
                    Container(
                      decoration: BoxDecoration(color: Coloressito.badgeBlue.withOpacity(0.08), shape: BoxShape.circle),
                      child: IconButton(onPressed: () => showDialog(context: context, builder: (_) => EstacionImageManagerDialog(estacionId: e.id)), icon: const Icon(Icons.image), color: Coloressito.badgeBlue, tooltip: 'Gestionar imágenes'),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      decoration: BoxDecoration(color: Coloressito.badgeBlue.withOpacity(0.08), shape: BoxShape.circle),
                      child: IconButton(onPressed: () => _showEditDialog(e), icon: const Icon(Icons.edit), color: Coloressito.badgeBlue),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      decoration: BoxDecoration(color: Coloressito.badgeRed.withOpacity(0.08), shape: BoxShape.circle),
                      child: IconButton(onPressed: () => _confirmDeactivate(e), icon: const Icon(Icons.delete), color: Coloressito.badgeRed),
                    ),
                  ])),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
