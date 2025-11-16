import 'package:flutter/material.dart';
import '../models/regioycomu.dart';
import 'package:tu_recorrido/utils/theme/colores.dart';
import 'package:tu_recorrido/services/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tu_recorrido/services/infra/firestore_service.dart';
import 'package:tu_recorrido/utils/docs/terminos_condiciones.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => RegistroScreenState();
}

class RegistroScreenState extends State<RegistroScreen> {
  // Form
  final formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController nombre = TextEditingController();
  final TextEditingController apodo = TextEditingController();
  final TextEditingController fecha = TextEditingController();
  final TextEditingController correo = TextEditingController();
  final TextEditingController contra = TextEditingController();

  // Región / Comuna
  String? regionSeleccionada;
  String? comunaSeleccionada;
  List<String> comunas = [];

  bool isLoading = false;
  bool _acceptedLegal = false; // debe estar marcado para permitir registro

  // Regex
  final RegExp nombreReg = RegExp(r"^[A-Za-zÁÉÍÓÚáéíóúÑñ ]{3,20}$");
  final RegExp apodoReg = RegExp(r"^[A-Za-z0-9_ -]{3,15}$");
  final RegExp contrasReg = RegExp(
      r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%\^&\*\(\)\[\]\-_=+\{\}\|;:',<\.>\/\?\\~`]).{8,}$");

  @override
  void dispose() {
    nombre.dispose();
    apodo.dispose();
    fecha.dispose();
    correo.dispose();
    contra.dispose();
    super.dispose();
  }

  Future<void> showCustomDateRangePicker(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initial = DateTime(now.year - 18, now.month, now.day);
    final DateTime first = DateTime(now.year - 100);
    final DateTime last = initial; // evita seleccionar una fecha futura
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() {
        fecha.text = "${picked.day.toString().padLeft(2, '0')}/"
            "${picked.month.toString().padLeft(2, '0')}/"
            "${picked.year}";
      });
    }
  }

  void onRegionChanged(String? region) {
    setState(() {
      regionSeleccionada = region;
      comunas = region != null ? regionesYComunas[region]! : [];
      comunaSeleccionada = null;
    });
  }

  // ====== MÉTODO 1: SUBMIT (Auth -> Firestore -> limpiar -> redirigir) ======
  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      setState(() {}); // fuerza mostrar errores
      return;
    }

    setState(() => isLoading = true);

    try {
      // print('🔄 Iniciando registro con email: ${correo.text.trim()}');
      // print('🔄 Firebase App: ${FirebaseAuth.instance.app.name}');

      // 1) Crear usuario en Auth
      final userCredential = await AuthService.registerWithEmail(
        email: correo.text.trim(),
        password: contra.text,
        displayName: nombre.text.trim(),
      );

      if (userCredential == null) {
        throw Exception('No se pudo crear el usuario.');
      }

      // 2) Guardar perfil completo en Firestore
      await _guardarDatosCompletos(userCredential.user!.uid);

      // 3) Limpiar formulario
      _limpiarFormulario();

      // 4) Feedback + redirección
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Registro exitoso. Ahora puedes iniciar sesión.'),
          backgroundColor: Colors.green,
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth/login');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      // print('🔥 FirebaseAuthException: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'La contraseña es muy débil.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Ya existe una cuenta con este correo.';
          break;
        case 'invalid-email':
          errorMessage = 'El correo no es válido.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'El registro con email/contraseña no está habilitado.';
          break;
        case 'invalid-api-key':
          errorMessage = 'Error de configuración: API key inválida.';
          break;
        case 'app-not-authorized':
          errorMessage = 'La app no está autorizada para usar Firebase Auth.';
          break;
        default:
          errorMessage = 'Error al registrar: ${e.code} - ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('❌ $errorMessage'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // print('🔥 Error general: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('❌ Error inesperado: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ====== MÉTODO AUXILIAR: Convertir fecha DD/MM/YYYY a ISO YYYY-MM-DD ======
  String? _toIsoFromDdMMyyyy(String ddmmyyyy) {
    try {
      final parts = ddmmyyyy.split('/');
      if (parts.length != 3) return null;
      final d = parts[0].padLeft(2, '0');
      final m = parts[1].padLeft(2, '0');
      final y = parts[2];
      return '$y-$m-$d'; // YYYY-MM-DD
    } catch (_) {
      return null;
    }
  }

  // ====== MÉTODO 2: Guardar datos completos del formulario en Firestore ======
  Future<void> _guardarDatosCompletos(String uid) async {
    final iso = _toIsoFromDdMMyyyy(fecha.text.trim());

    final userData = {
      'uid': uid,
      'nombre': nombre.text.trim(),
      'apodo': apodo.text.trim(),
      'email': correo.text.trim(),
      'fechaNacimiento': fecha.text.trim(), // DD/MM/YYYY (lo que muestras)
      'fechaNacimientoISO': iso, // YYYY-MM-DD (para queries)
      'region': regionSeleccionada ?? '',
      'comuna': comunaSeleccionada ?? '',
      'role': 'user',
      'activo': true,
      // createdAt/updatedAt los maneja FirestoreService.upsertUser()
    };
    // print('📁 Guardando datos completos del usuario en Firestore...');
    await FirestoreService.instance.upsertUser(uid: uid, data: userData);
    // print('✅ Datos guardados exitosamente en Firestore: $userData');
  }

  void _limpiarFormulario() {
    nombre.clear();
    apodo.clear();
    fecha.clear();
    correo.clear();
    contra.clear();
    setState(() {
      regionSeleccionada = null;
      comunaSeleccionada = null;
      comunas = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Coloressito.background,
      body: Center(
        child: Card(
          elevation: 6,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Text('Registro',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),

                        // Nombre
                        TextFormField(
                          controller: nombre,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            hintText: 'Ej: Juan Pérez',
                            errorStyle: TextStyle(height: 0.8),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'El nombre no puede quedar vacío';
                            }
                            if (v.trim().length < 3 || v.trim().length > 20) {
                              return 'Debe tener entre 3 y 20 caracteres';
                            }
                            if (!nombreReg.hasMatch(v.trim())) {
                              return 'Solo letras y espacios permitidos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Apodo
                        TextFormField(
                          controller: apodo,
                          decoration: const InputDecoration(
                            labelText: 'Apodo',
                            hintText: 'Ej: juanito123',
                            errorStyle: TextStyle(height: 0.8),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'El apodo no puede quedar vacío';
                            }
                            if (v.trim().length < 3 || v.trim().length > 15) {
                              return 'Apodo: entre 3 y 15 caracteres';
                            }
                            if (!apodoReg.hasMatch(v.trim())) {
                              return 'Caracteres inválidos en apodo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Fecha de nacimiento
                        TextFormField(
                          controller: fecha,
                          readOnly: true,
                          onTap: () => showCustomDateRangePicker(context),
                          decoration: const InputDecoration(
                            labelText: 'Fecha de nacimiento',
                            hintText: 'Seleccione su fecha',
                            errorStyle: TextStyle(height: 0.8),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'La fecha no puede quedar vacía';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Región
                        DropdownButtonFormField<String>(
                          initialValue: regionSeleccionada,
                          decoration: const InputDecoration(
                            labelText: 'Región',
                            hintText: 'Seleccione región',
                            errorStyle: TextStyle(height: 0.8),
                          ),
                          items: regionesYComunas.keys
                              .map((r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ))
                              .toList(),
                          onChanged: onRegionChanged,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Debe seleccionar una región';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Comuna
                        DropdownButtonFormField<String>(
                          initialValue: comunaSeleccionada,
                          decoration: const InputDecoration(
                            labelText: 'Comuna',
                            hintText: 'Seleccione comuna según región',
                            errorStyle: TextStyle(height: 0.8),
                          ),
                          items: comunas
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => comunaSeleccionada = v),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Debe seleccionar una comuna';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Correo
                        TextFormField(
                          controller: correo,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            hintText: 'Ej: usuario@ejemplo.com',
                            errorStyle: TextStyle(height: 0.8),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'El correo no puede quedar vacío';
                            }
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(v.trim())) {
                              return 'Ingrese un correo válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Contraseña
                        TextFormField(
                          controller: contra,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            hintText:
                                'Al menos 8 caracteres, mayúsculas, minúsculas, números y especial',
                            errorStyle: TextStyle(height: 0.8),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'La contraseña no puede quedar vacía';
                            }
                            if (!contrasReg.hasMatch(v)) {
                              return 'La contraseña debe tener mínimo 8 caracteres, incluir mayúscula, minúscula, número y caracter especial';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        // === Términos, Condiciones y Políticas ===
                        _LegalAgreementSection(onAcceptedChanged: (v){
                          setState((){
                            _acceptedLegal = v;
                          });
                        }),
                        const SizedBox(height: 12),

                        // ====== EL BOTÓN QUE LLAMA A submit() ======
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading || !_acceptedLegal ? null : submit,
                            child: isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Registrando...'),
                                    ],
                                  )
                                : const Text('Registrarse'),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // Botón cerrar
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      // Navegar de vuelta al login
                      Navigator.of(context).pushReplacementNamed('/auth/login');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===== Componente de aceptación legal =====
class _LegalAgreementSection extends StatefulWidget {
  final ValueChanged<bool> onAcceptedChanged;
  const _LegalAgreementSection({required this.onAcceptedChanged});
  @override
  State<_LegalAgreementSection> createState() => _LegalAgreementSectionState();
}

class _LegalAgreementSectionState extends State<_LegalAgreementSection> {
  bool accepted = false;
  void _openModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: DefaultTabController(
            length: 3,
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header con título y cerrar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Términos, Condiciones y Políticas',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Divider(height: 1),
                  // Tabs
                  const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'Términos'),
                      Tab(text: 'Privacidad'),
                      Tab(text: 'Seguridad'),
                    ],
                  ),
                  const Divider(height: 1),
                  // Contenido por pestaña
                  Flexible(
                    child: TabBarView(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: const _LegalDocBlock(
                            title: 'Términos y Condiciones',
                            text: LegalDocuments.termsAndConditionsText,
                          ),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: const _LegalDocBlock(
                            title: 'Política de Privacidad',
                            text: LegalDocuments.privacyPolicyText,
                          ),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: const _LegalDocBlock(
                            title: 'Política de Seguridad',
                            text: LegalDocuments.securityPolicyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Botón aceptar
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() { accepted = true; });
                              widget.onAcceptedChanged(true);
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('Acepto'),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _openModal,
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: const [
                      TextSpan(text: 'Al registrarte aceptas los ', style: TextStyle(color: Colors.black87)),
                      TextSpan(text: 'Términos, Condiciones y Políticas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      TextSpan(text: ' de Tu Recorrido.', style: TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Checkbox(
              value: accepted,
              onChanged: (v) {
                setState(() { accepted = v ?? false; });
                widget.onAcceptedChanged(accepted);
              },
            ),
          ],
        ),
        if(!accepted)
          const Padding(
            padding: EdgeInsets.only(left:4, top:4),
            child: Text('Debes aceptar los términos para continuar', style: TextStyle(fontSize: 11, color: Colors.red)),
          ),
      ],
    );
  }
}

class _LegalDocBlock extends StatelessWidget {
  final String title;
  final String text;
  const _LegalDocBlock({required this.title, required this.text});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(fontSize: 13, height: 1.35)),
      ],
    );
  }
}

