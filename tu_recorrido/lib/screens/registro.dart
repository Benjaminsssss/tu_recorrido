import 'package:flutter/material.dart';
import '../models/regioycomu.dart'; 
import '../utils/colores.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});// esta linea sirva para que no de error al crear la clase

  @override
  State<RegistroScreen> createState() => RegistroScreenState();
}

class RegistroScreenState extends State<RegistroScreen> {

  // este final es para manejar el estado del formulario
  final formKey = GlobalKey<FormState>();
  // Este es para manejar los controladores de los TextFormField
  final TextEditingController nombre = TextEditingController();
  final TextEditingController apodo = TextEditingController();
  final TextEditingController fecha = TextEditingController();
  final TextEditingController correo = TextEditingController();
  final TextEditingController contra = TextEditingController();
  //esto maneja la lista de regiones y comunas provenientes del regioycomu.dart
  // y las variables para la selección
  //la logica es que se crea una lista de comunas vacia y cuando se selecciona una region
  // se llena la lista de comunas con las comunas de esa region
  String? regionSeleccionada;
  String? comunaSeleccionada;
  List<String> comunas = [];

// creamos las expresiones regulares para validar los campos

  // nombre: letras y espacios, acentos permitidos, 3-20
  final RegExp nombreReg = RegExp(r"^[A-Za-zÁÉÍÓÚáéíóúÑñ ]{3,20}$");
  // apodo: 3-15, letras, numeros, guion bajo o espacio
  final RegExp apodoReg = RegExp(r"^[A-Za-z0-9_ -]{3,15}$");
  // contra: min 8, al menos minuscula, mayuscula, numero y caracter especial
  final RegExp contrasReg = RegExp(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%\^&\*\(\)\[\]\-_=+\{\}\|;:',<\.>\/\?\\~`]).{8,}$");

  // aqui se define la llave del formulario
  // ya que dispose sirve para eliminar el formulario cuando ya no se usa
  @override
  void dispose() {
    nombre.dispose();
    apodo.dispose();
    fecha.dispose();
    correo.dispose();
    contra.dispose();
    super.dispose();
  }

//future es un metodo asincrono, lo que significa que puede tardar un tiempo en completarse
// y no bloquea la interfaz de usuario mientras espera, su funcion es mostrar el datepicker
//el cual es un widget que permite al usuario seleccionar una fecha de un calendario
//es nativo de flutter
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

//este metodo rellena la lista de comunas segun la region seleccionada
  void onRegionChanged(String? region) {
    setState(() {
      regionSeleccionada = region;
      comunas = region != null ? regionesYComunas[region]! : [];
      comunaSeleccionada = null;
    });
  }

// este metodo sube los datos del formulario(añadir logica con la base de datos)
  void submit() {
    if (formKey.currentState?.validate() ?? false) {
      // éxito
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Registro'),
          content: const Text('Registro exitoso.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),// aqui se cierra el dialogo y se vuelve a la pantalla anterior
              child: const Text('Aceptar'),
            )
          ],
        ),
      );
    } else {
      // esto hace que se muestren los errores de validación
      setState(() {});
    }
  }

//esto construye la interfaz de usuario
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Pantalla que muestra el card centrado
      backgroundColor: Coloressito.background ,
      body: Center(
        child: Card(
          elevation: 6,// linea para dar sombra
          margin: const EdgeInsets.symmetric(horizontal: 18),// margen horizontal
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),// bordes redondeados
          child: Padding(
            padding: const EdgeInsets.all(14),// padding interno del card
            child: Stack(
              children: [
                // formulario
                SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,// esta hace que
                  // se validen los campos al interactuar con ellos
      
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Registro',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),

                        // Nombre
                        TextFormField(
                          controller: nombre,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            hintText: 'Ej: Juan Pérez',
                            errorStyle: TextStyle(height: 0.8),// ajusta la altura del error
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
                            errorStyle: TextStyle(height: 0.8),// ajusta la altura del error
                          ),
                          validator: (v) {// validacion de que si la variable es nula o esta vacia
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
                            errorStyle: TextStyle(height: 0.8),// ajusta la altura del error
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'La fecha no puede quedar vacía';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Region en donde se selecciona la comuna
                        // la logica es que al seleccionar una region se llena la lista de comunas
                        // y se selecciona la comuna
                        DropdownButtonFormField<String>(
                          initialValue: regionSeleccionada,
                          decoration: const InputDecoration(
                            labelText: 'Región',
                            hintText: 'Seleccione región',
                            errorStyle: TextStyle(height: 0.8),// ajusta la altura del error
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
                            errorStyle: TextStyle(height: 0.8),// ajusta la altura del error
                          ),
                          items: comunas
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            setState(() => comunaSeleccionada = v);
                          },
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
                            errorStyle: TextStyle(height: 0.8),// ajusta la altura del error
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'El correo no puede quedar vacío';
                            }
                            if (!v.contains('@') ||
                                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
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
                            hintText: 'Al menos 8 caracteres, mayúsculas, minúsculas, números y especial',
                            errorStyle: TextStyle(height: 0.8),// ajusta la altura del error
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

                        // Botón registrar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: submit,
                            child: const Text('Registrarse'),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // Botón X , aqui deberia volver al menu principal o al login respectivamente
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
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
