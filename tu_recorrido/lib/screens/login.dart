import 'package:flutter/material.dart';
import '../utils/colores.dart';
import '../screens/Menu.dart';

//AQUI creamos la clase de login , la cual sera stateful widget porque va a tener un formulario de login
// ya que otro tipo de widget no nos sirve ,por ejemplo stateless widget no nos sirve por que 
//este  sirve para cosas que no cambian , y en este caso el formulario de login si cambia.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});// esta ñoa sirve para que no de error al crear la clase
  //lo que hace es pasar la key al constructor de la clase padre, que es StatefulWidget
  // asi evitamos errores al crear la clase

  @override// sirve pra sobreescribir el metodo createState
  State<LoginScreen> createState() => _LoginScreenState();// esta linea crea el estado de la clase, el cual es _LoginScreenState
  // sirve para que el estado de la clase sea privado, es decir, que solo se pueda acceder desde esta clase
  //o invocarla desde otra clase
}
//creaciuon del cuerpo de la clase 
class _LoginScreenState extends State<LoginScreen> {

 final formKey = GlobalKey<FormState>(); // este final es para manejar el estado del formulario

 final TextEditingController correo = TextEditingController();
 final TextEditingController contra = TextEditingController();


 @override
  // este metodo se usa para liberar los recursos que ya no se usan
  // de esta formna evitamos fugas de memoria y aseguraramos un buen rendimiento de la app
  void dispose() {
    correo.dispose();
    contra.dispose();
    super.dispose();
  }

  // void es un tipo de dato que indica que una funcion no devuelve ningun valor, pero si puede realizar acciones
  // en este caso la funcion submit se encarga de enviar los datos del login
  void submit(){
    // el if se lee de la siguiente forma si el estado actual del formulario es valido
    // es decir, si todos los campos cumplen con las validaciones
    // el ?? es un operador , que sirve para asignar un valor por defecto
    // en este caso si formKey.currentState es null, entonces se asigna false
    // esto es para evitar errores en tiempo de ejecucion
    
    if(formKey.currentState?.validate() ?? false){
      // salio bien 
    if (correo.text == "usuario@ejemplo.com" && contra.text == "12345678") {
      // Navega a la pantalla principal 
      Navigator.of(context).pushReplacementNamed('/menu');
    } else {
      showDialog(
        context: context,
         builder: (_) => AlertDialog(
          title: const Text("login"),
          content: Text("Login  erroeo con el correo: ${correo.text}"),
          // la accion del boton es cerrar el dialogo
          // Navigator.of(context).pop() sirve para cerrar el dialogo
          // el context es el contexto actual de la app
          // el pop() es para cerrar la pantalla actual y volver a la anterior
          actions: [
            TextButton(onPressed: ()=> Navigator.of(context).pop(),
             child: const Text("Aceptar"))
          ],
         )
         );
         setState(() {});
  }
  }
  }


//AHORA CREAMOS EL WIDGET DE LA PANTALLa
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Coloressito.background,
      body: Center(
        child: Card(
          elevation: 5,// esto es para darle sombra al card
          // ESTE MMRGINM ES PARA QUE EL CARD NO ESTE PEGADO A LOS BORDES DE LA PANTALLA
          // Y LA CONSTANTE SYMMETRIC ES PARA QUE SEA SIMETRICO
          margin: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular( 12)),// esto es para darle bordes redondeados al card
          child: Padding
          (padding: const EdgeInsets.all(12),// esto es para darle un padding al card
          child: Stack(//stack sirve para apilar widgets uno encima de otro como si fuera una torre
          children: [
            SingleChildScrollView(//esto sirve para que  el conternido del carda sea scrollable es decir 
            // que se pueda scrollear si el contenido es mas grande que el card
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,// esto es para que las validaciones se hagan cuando el usuario interactue con el formulario
              child: Column(
                mainAxisSize: MainAxisSize.min,// esto es para que el column ocupe el minimo espacio posible
                children: [
                  // se crea una caja la cual contiene el nombre del wigdet pero se puede cambiar por un logo u otra cosa
                  const SizedBox(height: 12),
                  Text('Login',
                  style: Theme.of(context).textTheme.headlineMedium,// ESTE Estilo es para
                  // darle un estilo al texto, en este caso se usa el esilo de la app
                  ),
                  TextFormField(
                    controller: correo,// variable de controlador de texto, ES decir , lo que el usuario escribe
                    decoration: const InputDecoration(// simplemente es para darle estilo al textformfield
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {// validacion del campo correo , valor que el usuario ingresa 
                    // si el valor es nulo o esta vacio, entonces se muestra un mensaje de error
                      if (value == null || value.isEmpty) {
                        return 'Ingrese su correo';
                      }
                      if (!value.contains('@')) {
                        return 'Correo inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contra,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese su contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña es muy corta';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submit,
                      child: const Text('Ingresar'),// boton de ingresatr que deberia subir los datos a la base de datos
                      // y llevar a la pantalla principal
                    ),
                  ),
                ],
              ),
            ),

            )
          ],

          )
                  ),
      ),
      )
    );
  }
}
