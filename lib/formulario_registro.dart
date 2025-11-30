import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'controlador/basededatos.dart'; // Asegúrate que esta ruta sea correcta
import 'authentication/authentication.dart'; // Asegúrate que esta ruta sea correcta

class FormularioRegistro extends StatefulWidget {
  const FormularioRegistro({super.key});

  @override
  State<FormularioRegistro> createState() => _FormularioRegistroState();
}

class _FormularioRegistroState extends State<FormularioRegistro> {
  // Controladores y variables locales para ESTE formulario
  final List<String> _opcionesRegistro = ["RESIDENTE", "GUARDIA"];
  late String _itemSeleccionado;
  final _name = TextEditingController();
  final _edad = TextEditingController();
  final _rango = TextEditingController();
  final _calle = TextEditingController();
  final _colonia = TextEditingController();
  final _noInt = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _itemSeleccionado = _opcionesRegistro.first; // Inicia con "RESIDENTE"
  }

  @override
  void dispose() {
    // Limpia todos los controladores cuando el widget se destruye
    _name.dispose();
    _edad.dispose();
    _rango.dispose();
    _calle.dispose();
    _colonia.dispose();
    _noInt.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _registrarUsuario() async {
    // Ocultar el teclado
    FocusScope.of(context).unfocus();

    // Iniciar el indicador de carga
    setState(() => _isLoading = true);

    // --- Preparación y validación de datos ---
    final String email = _email.text.trim();
    final String password = _password.text.trim();
    final int? edadValue = int.tryParse(_edad.text);

    // Validaciones
    if (email.isEmpty || password.isEmpty) {
      _mostrarError("El correo y la contraseña son obligatorios.");
      return;
    }
    if (edadValue == null) {
      _mostrarError("El campo 'EDAD' debe ser un número válido.");
      return;
    }

    // --- Intento de registro ---
    try {
      UserCredential userCredential = await Auth()
          .microServicio
          .createUserWithEmailAndPassword(email: email, password: password);
      String uid = userCredential.user!.uid;

      if (_itemSeleccionado == "RESIDENTE") {
        var registroR = {
          'name': _name.text,
          'edad': edadValue,
          'domicilio': {'calle': _calle.text, 'colonia': _colonia.text, 'noInt': _noInt.text},
          'email': email, 'active': false, 'rol': 'residente',
        };
        await baseRemota.collection("residente").doc(uid).set(registroR);
      } else { // Guardia
        var query = await baseRemota.collection("guardia").get();
        bool noHayGuardias = query.docs.isEmpty;
        var registroG = {
          'name': _name.text, 'edad': edadValue, 'rango': _rango.text,
          'email': email, 'active': noHayGuardias, 'rol': 'guardia',
        };
        await baseRemota.collection("guardia").doc(uid).set(registroG);
      }

      if (context.mounted) {
        Navigator.pop(context, true); // Devuelve 'true' para indicar éxito
      }
    } on FirebaseAuthException catch (e) {
      _mostrarError("Error de registro: ${e.message}");
    } catch (e) {
      _mostrarError("Ocurrió un error inesperado: $e");
    } finally {
      // Detener el indicador de carga sin importar el resultado
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              items: _opcionesRegistro.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              value: _itemSeleccionado,
              onChanged: (val) => setState(() => _itemSeleccionado = val!),
            ),
            const SizedBox(height: 20),

            // --- Campos de texto ---
            TextField(controller: _name, decoration: const InputDecoration(labelText: "Nombre")),
            const SizedBox(height: 10),
            TextField(controller: _edad, decoration: const InputDecoration(labelText: "Edad"), keyboardType: TextInputType.number),
            const SizedBox(height: 10),

            if (_itemSeleccionado == "RESIDENTE") ...[
              TextField(controller: _calle, decoration: const InputDecoration(labelText: "Calle")),
              const SizedBox(height: 10),
              TextField(controller: _colonia, decoration: const InputDecoration(labelText: "Colonia")),
              const SizedBox(height: 10),
              TextField(controller: _noInt, decoration: const InputDecoration(labelText: "No. de Casa")),
            ] else ...[ // Campos para GUARDIA
              TextField(controller: _rango, decoration: const InputDecoration(labelText: "Rango")),
            ],

            const SizedBox(height: 10),
            TextField(controller: _email, decoration: const InputDecoration(labelText: "Correo Electrónico"), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 10),
            TextField(controller: _password, decoration: const InputDecoration(labelText: "Contraseña"), obscureText: true),

            const SizedBox(height: 20),

            // --- Botones de acción ---
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _registrarUsuario, child: const Text("REGISTRAR")),
                ],
              )
          ],
        ),
      ),
    );
  }
}
