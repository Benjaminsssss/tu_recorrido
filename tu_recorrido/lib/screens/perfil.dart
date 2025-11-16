import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:tu_recorrido/screens/escanerqr.dart';
import '../models/regioycomu.dart';
import '../models/user_state.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/colores.dart';
import 'login.dart';
import '../services/profile_service.dart';

class Perfil extends StatefulWidget {
  const Perfil({super.key});

  @override
  State<Perfil> createState() => _PerfilState();
}

enum PerfilModo { hub, configuracion }

class _PerfilState extends State<Perfil> with SingleTickerProviderStateMixin {
  PerfilModo _modo = PerfilModo.hub;
  double _sheetFraction = 0.92; // 92% alto al abrir
  bool _showingGeneralProgress = false;
  static const double minFraction = 0.7;
  static const double maxFraction = 0.92;
  late AnimationController _controller;
  late Animation<double> _blurAnim;
  late Animation<double> _dimAnim;

  String _selectedRegion = '';
  // Clave para capturar el widget del perfil (modo hub)
  final GlobalKey _captureKey = GlobalKey();
  String _selectedComuna = '';
  List<String> _comunas = [];
  Stream<Map<String, dynamic>>? _progresoStream;
  List<String> _sellos = [];
  List<String> _amigos = [];
  Locale? _selectedLocale;
  String? _photoBase64;
  String? _nombre;
  String? _correo;
  String? _nivel;
  Uint8List? _localBytes;


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _blurAnim = Tween<double>(begin: 0, end: 12).animate(_controller);
    _dimAnim = Tween<double>(begin: 0, end: 0.18).animate(_controller);
    _loadUser();
    _controller.forward();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    String? avatarB64;
    if (user != null) {
      avatarB64 = await ProfileService.getAvatarBase64(user.uid);
      // Inicializar regiones y comunas
      setState(() {
        if (_selectedRegion.isEmpty && regionesYComunas.isNotEmpty) {
          _selectedRegion = regionesYComunas.keys.first;
          _comunas = regionesYComunas[_selectedRegion] ?? [];
          if (_selectedComuna.isEmpty && _comunas.isNotEmpty) {
            _selectedComuna = _comunas.first;
            _updateProgresoStream(user.uid);
          }
        }
      });
    }
    setState(() {
      _photoBase64 = avatarB64;
      _nombre = user?.displayName ?? '';
      _correo = user?.email ?? '';
      _nivel = 'Nivel Viajero 1';
      _sellos = [];
      _amigos = [];
      _selectedLocale = const Locale('es');
    });
  }

  void _updateProgresoStream(String uid) {
    setState(() {
      _progresoStream = ProfileService.getComunaProgress(uid, _selectedComuna);
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _sheetFraction -=
          details.primaryDelta! / MediaQuery.of(context).size.height;
      _sheetFraction = _sheetFraction.clamp(minFraction, maxFraction);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_sheetFraction < 0.75) {
      _closeSheet();
    } else if (_sheetFraction > 0.85) {
      setState(() => _sheetFraction = maxFraction);
    } else {
      setState(() => _sheetFraction = minFraction);
    }
  }

  void _closeSheet() {
    HapticFeedback.lightImpact();
    _controller.reverse().then((_) {
      Navigator.of(context).maybePop();
    });
  }



  void _switchToHub() {
    // final userState = Provider.of<UserState>(context, listen: false);
    setState(() {
      _modo = PerfilModo.hub;
      // Si hay avatar persistido en Provider, úsalo como respaldo
      // Ya no se usa avatarUrl ni _photoUrl, solo base64/localBytes
    });
    HapticFeedback.lightImpact();
  }

  void _switchToConfiguracion() {
    setState(() => _modo = PerfilModo.configuracion);
    HapticFeedback.lightImpact();
  }



  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      key: _captureKey,
      child: Stack(
      children: [
        // Blur + dim del fondo
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _blurAnim.value,
                sigmaY: _blurAnim.value,
              ),
              child: Container(
                color: Color.fromARGB((_dimAnim.value * 255).round(), 0, 0, 0),
              ),
            );
          },
        ),
        // Sheet principal con degradado rural (beige a verde claro)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          left: 0,
          right: 0,
          bottom: 0,
          height: size.height * _sheetFraction,
          child: GestureDetector(
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  gradient: isDark
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFF5E9D2), // beige rural
                            Color(0xFFD6EFC7), // verde muy claro
                            Colors.white,
                          ],
                          stops: [0.0, 0.18, 1.0],
                        ),
                  color: isDark ? Coloressito.backgroundDark : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  elevation: 0,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Handle visual
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Color.fromARGB((0.35 * 255).round(), 188, 161,
                              119), // marrón claro
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _modo == PerfilModo.hub
                            ? _buildHub(context, isDark)
                            : _buildConfiguracion(context, isDark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildHub(BuildContext context, bool isDark) {
    final handle = _correo != null && _correo!.contains('@')
        ? '@${_correo!.split('@')[0].replaceAll(RegExp(r'\s'), '').toLowerCase()}'
        : '@usuario';
    // final userState = Provider.of<UserState>(context);

    // Determinar fuente de avatar: prioridad local bytes > base64 > ícono
    ImageProvider? avatarProvider;
    if (_localBytes != null) {
      avatarProvider = MemoryImage(_localBytes!);
    } else if (_photoBase64 != null && _photoBase64!.isNotEmpty) {
      try {
        avatarProvider = MemoryImage(base64Decode(_photoBase64!));
      } catch (_) {}
    }
    // ...existing code...
    return Container(
      color: isDark ? Coloressito.backgroundDark : Colors.white,
      child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // Header compacto
        Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFD6EFC7), // verde claro rural
              backgroundImage: avatarProvider,
              child: (avatarProvider == null)
                  ? const Icon(Icons.person,
                      color: Color(0xFF7C6F57), // marrón rural
                      size: 40)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              _nombre ?? '',
              style: const TextStyle(
                fontFamily: 'Pacifico',
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Color(0xFF7C6F57), // marrón rural
              ),
            ),
            const SizedBox(height: 2),
            Text(handle,
                style: const TextStyle(color: Color(0xFFBCA177), fontSize: 15)),
            const SizedBox(height: 2),
            Text(_nivel ?? 'Nivel Viajero 1',
                style: const TextStyle(
                    color: Color(0xFF7C9A5B), // verde hoja
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ],
        ),
        const SizedBox(height: 18),
        // Quick actions
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _QuickAction(
                icon: Icons.settings,
                label: 'Ajustes',
                onTap: _switchToConfiguracion,
                iconColor: Color(0xFFBCA177)),
            _QuickAction(
              icon: Icons.qr_code,
              label: 'QR',
              onTap: () {
                Navigator.pop(context); // Cerrar el bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EscanerQRScreen()),
                );
              },
              iconColor: Color(0xFF7C6F57),
            ),
            _QuickAction(
                icon: Icons.share,
                label: 'Compartir',
                onTap: _showShareOptions,
                iconColor: Color(0xFF7C9A5B)),
          ],
        ),
        const SizedBox(height: 18),
        // Separador rural
        Divider(
            height: 1,
            thickness: 1,
            color: Color.fromARGB((0.18 * 255).round(), 188, 161, 119)),
        const SizedBox(height: 14),
        _buildComunaProgressCard(),
        const SizedBox(height: 10),
        Divider(
            height: 1,
            thickness: 1,
            color: Color.fromARGB((0.18 * 255).round(), 188, 161, 119)),
        const SizedBox(height: 14),
        _buildSavedPlacesCard(),
        const SizedBox(height: 10),
        Divider(
            height: 1,
            thickness: 1,
            color: Color.fromARGB((0.18 * 255).round(), 188, 161, 119)),
        const SizedBox(height: 14),
        _buildStampsCard(),
        const SizedBox(height: 10),
        Divider(
            height: 1,
            thickness: 1,
            color: Color.fromARGB((0.18 * 255).round(), 188, 161, 119)),
     
        const SizedBox(height: 10),
        Divider(
            height: 1,
            thickness: 1,
            color: Color.fromARGB((0.18 * 255).round(), 188, 161, 119)),
        const SizedBox(height: 14),
        _buildFriendsCard(),
      ],
    ),
    );
  }



  Widget _buildConfiguracion(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Volver',
              onPressed: _switchToHub,
              splashRadius: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Ajustes',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Selector de idioma
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: isDark ? Colors.grey[850] : Colors.grey[50],
          child: ListTile(
            leading: Icon(Icons.language, color: Coloressito.adventureGreen),
            title: const Text('Idioma'),
            subtitle: Text(_selectedLocale?.languageCode.toUpperCase() ?? 'ES'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(context),
          ),
        ),
        const SizedBox(height: 12),
        // Tema (placeholder para futuro)
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: isDark ? Colors.grey[850] : Colors.grey[50],
          child: ListTile(
            leading:
                Icon(Icons.brightness_6, color: Coloressito.adventureGreen),
            title: const Text('Tema'),
            subtitle: Text(isDark ? 'Oscuro' : 'Claro'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 12),
        // Notificaciones (placeholder para futuro)
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: isDark ? Colors.grey[850] : Colors.grey[50],
          child: ListTile(
            leading:
                Icon(Icons.notifications, color: Coloressito.adventureGreen),
            title: const Text('Notificaciones'),
            subtitle: const Text('Configurar alertas'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 12),
        // Privacidad (placeholder para futuro)
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: isDark ? Colors.grey[850] : Colors.grey[50],
          child: ListTile(
            leading: Icon(Icons.privacy_tip, color: Coloressito.adventureGreen),
            title: const Text('Privacidad'),
            subtitle: const Text('Configurar privacidad'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 12),
        // Debug Auth (temporal)
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: Colors.orange[50],
          child: ListTile(
            leading: Icon(Icons.bug_report, color: Colors.orange[600]),
            title: const Text('Debug Auth'),
            subtitle: const Text('Diagnosticar problema de auth'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, '/debug-auth'),
          ),
        ),
        const SizedBox(height: 32),
        // Cerrar sesión
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Cerrar sesión',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Español'),
              leading: Icon(
                _selectedLocale == const Locale('es')
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: _selectedLocale == const Locale('es')
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
              onTap: () {
                final v = const Locale('es');
                setState(() => _selectedLocale = v);
                context.setLocale(v);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              leading: Icon(
                _selectedLocale == const Locale('en')
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: _selectedLocale == const Locale('en')
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
              onTap: () {
                final v = const Locale('en');
                setState(() => _selectedLocale = v);
                context.setLocale(v);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // Primero cerrar el bottom sheet con animación
      if (mounted) {
        _controller.reverse().then((_) async {
          // Limpiar datos del UserState ANTES de cerrar sesión
          final userState = context.read<UserState>();
          await userState.clearUserData();
          
          // Cerrar sesión en Firebase
          await FirebaseAuth.instance.signOut();

          // Navegar a la pantalla de login eliminando todas las rutas anteriores
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        });
      }
    }
  }



  // --- Captura y compartición del perfil ---
  Future<Uint8List?> _captureProfilePng() async {
    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final dpr = MediaQuery.of(context).devicePixelRatio;
      final image = await boundary.toImage(pixelRatio: dpr);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo capturar el perfil: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _shareAsImage() async {
    final png = await _captureProfilePng();
    if (png == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/perfil_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(png);
    final params = ShareParams(
      files: [XFile(file.path, mimeType: 'image/png', name: 'perfil.png')],
      text: 'Mi perfil en Tu Recorrido',
    );
    await SharePlus.instance.share(params);
  }

  Future<void> _uploadAndShareLink() async {
    try {
      final png = await _captureProfilePng();
      if (png == null) return;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
      final ref = FirebaseStorage.instance
          .ref()
          .child('shared_profiles')
          .child('${uid}_${DateTime.now().millisecondsSinceEpoch}.png');
      await ref.putData(
        png,
        SettableMetadata(contentType: 'image/png'),
      );
      final url = await ref.getDownloadURL();
  await SharePlus.instance.share(ShareParams(text: 'Mira mi perfil en Tu Recorrido: $url'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo compartir el enlace: $e')),
        );
      }
    }
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Compartir como imagen'),
                onTap: () async {
                  Navigator.pop(context);
                  await _shareAsImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Subir y compartir link'),
                onTap: () async {
                  Navigator.pop(context);
                  await _uploadAndShareLink();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavedPlacesCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 0,
      color: Coloressito.surfaceLight,
      child: InkWell(
        onTap: () {
          // Navegar a la pantalla de lugares guardados
          Navigator.pushNamed(context, '/saved-places');
        },
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: Color(0xFF2B6B7F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lugares guardados',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ver tus lugares favoritos',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStampsCard() {
    final empty = _sellos.isEmpty;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 0,
      color: Coloressito.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sellos recientes',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: empty
                  ? Center(
                      child: Text(
                          'Sin sellos. Explora cerca para conseguir uno.',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _sellos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => CircleAvatar(
                        backgroundColor: Coloressito.badgeBlue,
                        child: Text(_sellos[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComunaProgressCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 0,
      color: Coloressito.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Progreso',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: Icon(
                        _showingGeneralProgress ? Icons.location_on : Icons.public,
                        size: 20,
                      ),
                      label: Text(
                        _showingGeneralProgress ? 'Ver por comuna' : 'Ver total país',
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        setState(() {
                          _showingGeneralProgress = !_showingGeneralProgress;
                          if (_showingGeneralProgress) {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              _progresoStream = ProfileService.getTotalProgress(user.uid);
                            }
                          } else if (_selectedComuna.isNotEmpty) {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              _updateProgresoStream(user.uid);
                            }
                          }
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (!_showingGeneralProgress) ...[
              Row(
                children: [
                  Text(
                    'Región: ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedRegion.isEmpty ? null : _selectedRegion,
                      hint: const Text('Selecciona una región'),
                      selectedItemBuilder: (context) {
                        final list = regionesYComunas.keys.toList();
                        return list
                            .map((region) => Text(
                                  region,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ))
                            .toList();
                      },
                      items: regionesYComunas.keys.map((region) {
                        return DropdownMenuItem(
                          value: region,
                          child: Text(region),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedRegion = newValue;
                            _comunas = regionesYComunas[newValue] ?? [];
                            _selectedComuna = _comunas.isNotEmpty ? _comunas.first : '';
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              _updateProgresoStream(user.uid);
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Comuna: ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedComuna.isEmpty ? null : _selectedComuna,
                      hint: const Text('Selecciona una comuna'),
                      selectedItemBuilder: (context) {
                        final list = _comunas;
                        return list
                            .map((comuna) => Text(
                                  comuna,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ))
                            .toList();
                      },
                      items: _comunas.map((comuna) {
                        return DropdownMenuItem(
                          value: comuna,
                          child: Text(comuna),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedComuna = newValue;
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              _updateProgresoStream(user.uid);
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
            if (_progresoStream != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: MediaQuery.of(context).size.width - 40,
                child: StreamBuilder<Map<String, dynamic>>(
                  stream: _progresoStream,
                  builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final progress = snapshot.data!;
                  final visitados = progress['visitados'] ?? 0;
                  final total = progress['total'] ?? 0;
                  final porcentaje = total > 0 ? (visitados / total * 100) : 0.0;

                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                        _showingGeneralProgress 
                            ? 'Progreso total en Chile'
                            : 'Progreso en $_selectedComuna',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: porcentaje / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$visitados de $total lugares visitados (${porcentaje.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildFriendsCard() {
    final empty = _amigos.isEmpty;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 0,
      color: Coloressito.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Amigos cercanos',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: empty
                  ? Center(
                      child: Text(
                          'Sin amigos cercanos. Explora cerca para conectar.',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _amigos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => CircleAvatar(
                        backgroundColor: Coloressito.badgeGreen,
                        child: Text(_amigos[i]),
                      ),
                    ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Ver todos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF5E9D2), // beige rural
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB((0.13 * 255).round(), 188, 161, 119),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFFBCA177), width: 1.2),
            ),
            child: Icon(icon,
                color: iconColor ?? const Color(0xFF7C9A5B), size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF7C6F57))),
      ],
    );
  }
}
