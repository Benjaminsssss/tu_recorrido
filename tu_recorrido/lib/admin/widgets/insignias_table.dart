import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/insignia.dart';
import '../../models/estacion.dart';
import '../../services/insignia_service.dart';
import '../../services/estacion_service.dart';
import '../../services/storage_service.dart';
import '../../utils/colores.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InsigniasTable extends StatefulWidget {
  const InsigniasTable({super.key});

  @override
  State<InsigniasTable> createState() => _InsigniasTableState();
}

class _InsigniasTableState extends State<InsigniasTable> {
  bool _loading = true;
  List<Insignia> _insignias = [];
  Map<String, Estacion> _estacionPorInsignia = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _insignias = await InsigniaService.obtenerTodas();
      final estaciones = await EstacionService.obtenerEstacionesActivas();
      _estacionPorInsignia.clear();
      for (final e in estaciones) {
        final ref = e.insigniaID;
        if (ref != null) _estacionPorInsignia[ref.id] = e;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando insignias: $e')));
      _insignias = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _crearInsignia() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Crear insignia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreController, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: descripcionController, decoration: const InputDecoration(labelText: 'Descripción')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            final nombre = nombreController.text.trim();
            final desc = descripcionController.text.trim();
            if (nombre.isEmpty || desc.isEmpty) return;
            Navigator.of(dialogContext).pop();
            if (kIsWeb) {
              final bytes = await picked.readAsBytes();
              await InsigniaService.createInsigniaWithImage(imageBytes: bytes, fileName: picked.name, nombre: nombre, descripcion: desc);
            } else {
              final file = File(picked.path);
              await InsigniaService.createInsigniaWithImage(imageFile: file, nombre: nombre, descripcion: desc);
            }
            await _load();
          }, child: const Text('Crear')),
        ],
      ),
    );
  }

  Future<void> _asignarInsignia(String insigniaId) async {
    final todas = await EstacionService.obtenerEstacionesActivas();
    final estaciones = todas.where((e) => e.insigniaID == null).toList();
    if (estaciones.isEmpty) {
      await showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Asignar insignia'), content: const Text('No hay estaciones disponibles sin insignia.'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Aceptar'))]));
      return;
    }
    String? estacionSeleccionadaId;
    await showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Asignar a estación'), content: SizedBox(width: double.maxFinite, child: ListView.builder(shrinkWrap: true, itemCount: estaciones.length, itemBuilder: (c,i){ final e = estaciones[i]; return RadioListTile<String>(title: Text(e.nombre), subtitle: Text(e.codigo), value: e.id, groupValue: estacionSeleccionadaId, onChanged: (v){ setState((){ estacionSeleccionadaId = v; }); }); })), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')), ElevatedButton(onPressed: () async { if (estacionSeleccionadaId == null) return; Navigator.of(ctx).pop(); await InsigniaService.assignInsigniaToEstacion(insigniaId: insigniaId, estacionId: estacionSeleccionadaId!); await _load(); }, child: const Text('Asignar'))]));
  }

  Future<void> _otorgarInsignia(String insigniaId) async {
    final emailController = TextEditingController();
    final uidController = TextEditingController();
    await showDialog(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Otorgar insignia'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email (opcional)')), const SizedBox(height:8), Text('O ingresa UID si no tienes email', style: Theme.of(dialogContext).textTheme.bodySmall), TextField(controller: uidController, decoration: const InputDecoration(labelText: 'UID (opcional)'))]), actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')), ElevatedButton(onPressed: () async { final email = emailController.text.trim(); final uid = uidController.text.trim(); if (email.isEmpty && uid.isEmpty) return; Navigator.of(dialogContext).pop(); String? targetUid = uid.isNotEmpty ? uid : null; if (targetUid == null && email.isNotEmpty) { final query = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get(); if (query.docs.isEmpty) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario no encontrado por email'))); return; } targetUid = query.docs.first.id; } try { await InsigniaService.otorgarInsigniaAUsuario(userId: targetUid!, insigniaId: insigniaId); if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insignia otorgada'))); } catch (e) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al otorgar insignia: $e'))); } }, child: const Text('Otorgar'))]));
  }

  Future<void> _editarInsignia(Insignia ins) async {
    final nombreCtrl = TextEditingController(text: ins.nombre);
    final descCtrl = TextEditingController(text: ins.descripcion);
    XFile? picked;
    final picker = ImagePicker();

    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context,setStateSB){ return AlertDialog(title: const Text('Editar insignia'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')), TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción')), const SizedBox(height:8), Row(children: [ElevatedButton.icon(onPressed: () async { final p = await picker.pickImage(source: ImageSource.gallery); if (p != null) setStateSB(() => picked = p); }, icon: const Icon(Icons.image), label: const Text('Reemplazar imagen')), const SizedBox(width:8), if (picked != null) const Icon(Icons.check_circle, color: Colors.green)])]), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')), ElevatedButton(onPressed: () async { final nombre = nombreCtrl.text.trim(); final desc = descCtrl.text.trim(); if (nombre.isEmpty || desc.isEmpty) return; Navigator.of(ctx).pop(); try { Map<String,dynamic> changes = {'nombre': nombre, 'descripcion': desc}; if (picked != null) { if (kIsWeb) { final bytes = await picked!.readAsBytes(); final path = 'insignias/${ins.id}_${picked!.name}'; final url = await StorageService.instance.uploadBytes(bytes, path, contentType: 'image/jpeg'); changes['imagenUrl'] = url; } else { final file = File(picked!.path); final ext = file.path.split('.').last; final path = 'insignias/${ins.id}.$ext'; final url = await StorageService.instance.uploadFile(file, path, contentType: 'image/jpeg'); changes['imagenUrl'] = url; } } await InsigniaService.actualizarInsignia(ins.id, changes); await _load(); } catch (e) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error editando insignia: $e'))); } }, child: const Text('Guardar'))]); }));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.black87),
            const SizedBox(width: 8),
            const Text('Gestión de Insignias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            ElevatedButton.icon(onPressed: _crearInsignia, icon: const Icon(Icons.add), label: const Text('Crear'), style: ElevatedButton.styleFrom(backgroundColor: Coloressito.adventureGreen)),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Nombre')),
              DataColumn(label: Text('Descripción')),
              DataColumn(label: Text('Imagen')),
              DataColumn(label: Text('Asignada a')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: _insignias.map((ins) {
              final assigned = _estacionPorInsignia[ins.id];
              return DataRow(cells: [
                DataCell(SizedBox(width: 200, child: Text(ins.nombre, overflow: TextOverflow.ellipsis))),
                DataCell(SizedBox(width: 350, child: Text(ins.descripcion, overflow: TextOverflow.ellipsis))),
                DataCell(ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(ins.imagenUrl, width: 80, height: 48, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width:80,height:48,color:Colors.grey)))),
                DataCell(Text(assigned?.nombre ?? '-')),
                DataCell(Row(children: [
                  if (assigned == null) IconButton(onPressed: () => _asignarInsignia(ins.id), icon: const Icon(Icons.link), tooltip: 'Asignar a estación'),
                  IconButton(onPressed: () => _otorgarInsignia(ins.id), icon: const Icon(Icons.emoji_events), tooltip: 'Otorgar a usuario'),
                  IconButton(onPressed: () => _editarInsignia(ins), icon: const Icon(Icons.edit), tooltip: 'Editar'),
                  IconButton(onPressed: () async { await InsigniaService.deleteInsignia(ins.id); await _load(); }, icon: const Icon(Icons.delete_forever), tooltip: 'Eliminar'),
                ])),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
