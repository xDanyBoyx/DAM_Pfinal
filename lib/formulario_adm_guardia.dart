import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'controlador/basededatos.dart';
import 'authentication/authentication.dart';
import 'modelo/guardia.dart';

class FormularioAdminGuardia extends StatefulWidget {
  final Guardia? guardiaAEditar;
  final String rangoDelUsuarioActual;

  const FormularioAdminGuardia({super.key, this.guardiaAEditar,required this.rangoDelUsuarioActual,});

  @override
  State<FormularioAdminGuardia> createState() => _FormularioAdminGuardiaState();
}

class _FormularioAdminGuardiaState extends State<FormularioAdminGuardia> {
  // Controladores para los campos del formulario
  final TextEditingController _name = TextEditingController();
  final TextEditingController _edad = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _rango = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Variable para el rango seleccionado
  String _rangoSeleccionado = 'guardia';
  late bool _esModoEdicion;

  @override
  void initState() {
    super.initState();
    _esModoEdicion = widget.guardiaAEditar != null;

    if (_esModoEdicion) {
      final guardia = widget.guardiaAEditar!;
      _name.text = guardia.name;
      _edad.text = guardia.edad.toString();
      _email.text = guardia.email;
      // La contraseña no se debe precargar por seguridad
      _rango.text = guardia.rango;
      _rangoSeleccionado = guardia.rango;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esModoEdicion ? 'Editar Guardia' : 'Registrar Nuevo Guardia'),
        backgroundColor: Colors.indigo.shade300,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextFormField(
                  _name, 'Nombre Completo',
                  Icons.person),
              const SizedBox(height: 15),
              _buildTextFormField(
                  _edad, 'Edad',
                  Icons.cake, keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              if (_esModoEdicion)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  child: Text("Email (no editable): ${_email.text}", style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                )
              else
                _buildTextFormField(_email, 'Email', Icons.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 15),
              _buildTextFormField(
                  _password, 'Contraseña',
                  Icons.lock,
                  obscureText: true,
                  esRequerido: !_esModoEdicion
              ),
              const SizedBox(height: 15),
              // Dropdown para seleccionar el ROL
              const Text('Asignar Rol:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _rangoSeleccionado,
                // --- LÓGICA CLAVE PARA LAS OPCIONES ---
                items: () {
                  // Empieza con las opciones básicas
                  List<String> opciones = ['guardia', 'sherif'];

                  // Si el usuario que abre el formulario es un 'admin',
                  // entonces se le añade la opción de crear otro 'admin'.
                  if (widget.rangoDelUsuarioActual == 'admin') {
                    opciones.add('admin');
                  }
                  // Construye los DropdownMenuItem a partir de la lista de opciones filtrada
                  return opciones.map((label) => DropdownMenuItem(
                    value: label,
                    child: Text(label),
                  )).toList();
                }(),
                onChanged: (value) {
                  setState(() {
                    _rangoSeleccionado = value!;
                  });
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.shield),
                  border: OutlineInputBorder(),
                ),
                validator: (value) { // <-- Añadimos el validador que se borró
                  if (value == null || value.isEmpty) {
                    return 'Debe seleccionar un rango';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              // Botón de Registro
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _guardarCambios,
                child: Text(
                  _esModoEdicion ? 'Guardar Cambios' : 'Registrar Guardia',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 6. RENOMBRAMOS LA FUNCIÓN Y LE AÑADIMOS LA LÓGICA DE ACTUALIZACIÓN
  void _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_esModoEdicion) {
      await _actualizarGuardia();
    } else {
      await _registrarGuardia();
    }
  }

  // --- NUEVA FUNCIÓN PARA ACTUALIZAR ---
  Future<void> _actualizarGuardia() async {
    final BuildContext currentContext = context;
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final datosActualizados = {
        'name': _name.text,
        'edad': int.tryParse(_edad.text) ?? 0,
        'rango': _rangoSeleccionado,
      };

      // Si el campo de contraseña no está vacío, la actualizamos.
      if (_password.text.isNotEmpty) {
        // TODO: Implementar la actualización de contraseña en Firebase Auth (es una operación sensible)
        // Por ahora, solo actualizamos el campo en Firestore, NO la contraseña real de login.
        datosActualizados['password'] = _password.text;
        print("ADVERTENCIA: La contraseña solo se actualizó en Firestore, no en Firebase Auth.");
      }

      await baseRemota
          .collection("guardia")
          .doc(widget.guardiaAEditar!.id)
          .update(datosActualizados);

      if (!currentContext.mounted) return;
      Navigator.of(currentContext).pop(); // Cierra loading
      Navigator.of(currentContext).pop(); // Vuelve a la lista

      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Guardia actualizado exitosamente.'), backgroundColor: Colors.green),
      );

    } catch (e) {
      if (!currentContext.mounted) return;
      Navigator.of(currentContext).pop(); // Cierra loading
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Widget reutilizable para crear campos de texto
  Widget _buildTextFormField(TextEditingController controller, String label, IconData icon,
      {bool obscureText = false,
        TextInputType keyboardType = TextInputType.text,
        bool esRequerido = true}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (esRequerido && (value == null || value.isEmpty)) {
          return 'Por favor, rellena este campo';
        }
        return null;
      },
    );
  }

  // --- Lógica de Registro ---
  Future<void> _registrarGuardia() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final BuildContext currentContext = context;

    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final Auth authService = Auth();
      final String resultado = await authService.inscribir(
        _email.text.trim(),
        _password.text.trim(),
      );

      if (resultado == "ok") {

        final User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception("No se pudo obtener el usuario recién creado.");
        }
        final String uid = user.uid;

        final int edadValue = int.tryParse(_edad.text) ?? 0;
        final datosGuardia = {
          'name': _name.text,
          'edad': edadValue,
          'rango': _rangoSeleccionado,
          'email': _email.text.trim(),
          'password': _password.text.trim(),
          'active': true,
          'fecha_registro': FieldValue.serverTimestamp(),
        };

        // Guardar en la colección 'guardia'
        // Usamos la variable 'baseRemota' que debe ser global en 'basededatos.dart'
        await baseRemota.collection("guardia").doc(uid).set(datosGuardia);

        if (!currentContext.mounted) return;

        Navigator.of(currentContext).pop(); // Cierra el loading
        Navigator.of(currentContext).pop(); // Cierra la pantalla de registro

        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Guardia registrado exitosamente.'), backgroundColor: Colors.green),
        );
      } else {
        // Si el resultado no es "ok", es un mensaje de error devuelto por tu método.
        if (!currentContext.mounted) return;
        Navigator.of(currentContext).pop(); // Cierra el loading
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text(resultado), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // Este catch ahora es para errores inesperados.
      if (!currentContext.mounted) return;
      Navigator.of(currentContext).pop(); // Cierra el loading
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _edad.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
}
