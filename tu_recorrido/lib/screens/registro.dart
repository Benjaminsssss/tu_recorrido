import 'package:flutter/material.dart';
import '../models/regioycomu.dart';
import '../utils/colores.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

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
      print('🔄 Iniciando registro con email: ${correo.text.trim()}');
      print('🔄 Firebase App: ${FirebaseAuth.instance.app.name}');

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
      print('🔥 FirebaseAuthException: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'La contraseña es muy débil.'; break;
        case 'email-already-in-use':
          errorMessage = 'Ya existe una cuenta con este correo.'; break;
        case 'invalid-email':
          errorMessage = 'El correo no es válido.'; break;
        case 'operation-not-allowed':
          errorMessage = 'El registro con email/contraseña no está habilitado.'; break;
        case 'invalid-api-key':
          errorMessage = 'Error de configuración: API key inválida.'; break;
        case 'app-not-authorized':
          errorMessage = 'La app no está autorizada para usar Firebase Auth.'; break;
        default:
          errorMessage = 'Error al registrar: ${e.code} - ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $errorMessage'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('🔥 Error general: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error inesperado: $e'), backgroundColor: Colors.red),
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
      'fechaNacimiento': fecha.text.trim(),     // DD/MM/YYYY (lo que muestras)
      'fechaNacimientoISO': iso,                // YYYY-MM-DD (para queries)
      'region': regionSeleccionada ?? '',
      'comuna': comunaSeleccionada ?? '',
      'activo': true,
      // createdAt/updatedAt los maneja FirestoreService.upsertUser()
    };

    print('📁 Guardando datos completos del usuario en Firestore...');
    await FirestoreService.instance.upsertUser(uid: uid, data: userData);
    print('✅ Datos guardados exitosamente en Firestore: $userData');
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        Text('Registro', style: Theme.of(context).textTheme.titleLarge),
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
                          onChanged: (v) => setState(() => comunaSeleccionada = v),
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

                        // ====== EL BOTÓN QUE LLAMA A submit() ======
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : submit,
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
