import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'controlador/basededatos.dart';
import 'authentication/authentication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FormularioRegistro extends StatefulWidget {
  const FormularioRegistro({super.key});

  @override
  State<FormularioRegistro> createState() => _FormularioRegistroState();
}

class _FormularioRegistroState extends State<FormularioRegistro> {
  // Variables dinámicas
  bool _existeAlMenosUnGuardia = false;
  bool _esPrimerGuardia = false;

  // Opciones dinámicas (solo RESIDENTE si ya existe guardia)
  List<String> get opcionesRegistro {
    if (_existeAlMenosUnGuardia) {
      return ["RESIDENTE"];
    }
    return ["RESIDENTE", "GUARDIA"];
  }

  late String _itemSeleccionado;

  // Rangos disponibles SOLO si no es primer guardia
  final List<String> _rangosDisponibles = ["sheriff", "guardia"];
  String? _rangoSeleccionado;

  // Controladores
  final _name = TextEditingController();
  final _edad = TextEditingController();
  final _calle = TextEditingController();
  final _colonia = TextEditingController();
  final _noInt = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _itemSeleccionado = "RESIDENTE";
    _verificarGuardiasExistentes();
  }

  @override
  void dispose() {
    _name.dispose();
    _edad.dispose();
    _calle.dispose();
    _colonia.dispose();
    _noInt.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // Verifica si ya existe algún guardia
  Future<void> _verificarGuardiasExistentes() async {
    var query = await baseRemota.collection("guardia").get();

    setState(() {
      _existeAlMenosUnGuardia = query.docs.isNotEmpty;
    });
  }

  // Verifica si este guardia será el primero
  Future<void> _verificarSiEsPrimerGuardia() async {
    var query = await baseRemota.collection("guardia").get();

    setState(() {
      _esPrimerGuardia = query.docs.isEmpty;
    });

    if (_esPrimerGuardia) {
      _rangoSeleccionado = "admin";
    } else {
      _rangoSeleccionado = null;
    }
  }

  Future<void> _registrarUsuario() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final String email = _email.text.trim();
    final String password = _password.text.trim();
    final int? edadValue = int.tryParse(_edad.text);

    if (email.isEmpty || password.isEmpty) {
      _mostrarError("El correo y la contraseña son obligatorios.");
      return;
    }

    if (edadValue == null) {
      _mostrarError("La edad debe ser un número válido.");
      return;
    }

    // Validar rango si no es el primer guardia
    if (_itemSeleccionado == "GUARDIA" && !_esPrimerGuardia) {
      if (_rangoSeleccionado == null) {
        _mostrarError("Debes seleccionar un rango para el guardia.");
        return;
      }
    }

    try {
      UserCredential userCredential =
      await Auth().microServicio.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      if (_itemSeleccionado == "RESIDENTE") {
        await baseRemota.collection("residente").doc(uid).set({
          'name': _name.text,
          'edad': edadValue,
          'domicilio': {
            'calle': _calle.text,
            'colonia': _colonia.text,
            'noInt': _noInt.text
          },
          'email': email,
          'active': false,
          'rol': 'residente',
          'password': password,
          'fecha_registro': FieldValue.serverTimestamp(),
        });
      } else {
        await _verificarSiEsPrimerGuardia();

        await baseRemota.collection("guardia").doc(uid).set({
          'name': _name.text,
          'edad': edadValue,
          'rango': _rangoSeleccionado, // admin si es el primero
          'email': email,
          'active': _esPrimerGuardia, // solo el primero es true
          'rol': 'guardia',
          'password': password,
          'fecha_registro': FieldValue.serverTimestamp(),
        });
      }

      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      _mostrarError("Error de registro: ${e.message}");
    } catch (e) {
      _mostrarError("Error inesperado: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dropdown dinámico
            DropdownButtonFormField<String>(
              items: opcionesRegistro
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              value: _itemSeleccionado,
              onChanged: (val) async {
                setState(() => _itemSeleccionado = val!);

                if (_itemSeleccionado == "GUARDIA") {
                  await _verificarSiEsPrimerGuardia();
                }
              },
            ),

            // Mensaje si ya NO se permite registrar guardias
            if (_existeAlMenosUnGuardia)

            const SizedBox(height: 20),

            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _edad,
              decoration: const InputDecoration(labelText: "Edad"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),

            if (_itemSeleccionado == "RESIDENTE") ...[
              TextField(
                controller: _calle,
                decoration: const InputDecoration(labelText: "Calle"),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _colonia,
                decoration: const InputDecoration(labelText: "Colonia"),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _noInt,
                decoration: const InputDecoration(labelText: "No. de Casa"),
              ),
            ] else ...[
              if (_esPrimerGuardia)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text(
                    "Este será el PRIMER guardia.\nRango asignado: ADMIN",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: "Rango", border: OutlineInputBorder()),
                  value: _rangoSeleccionado,
                  items: _rangosDisponibles
                      .map((r) =>
                      DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _rangoSeleccionado = value),
                ),
            ],

            const SizedBox(height: 10),

            TextField(
              controller: _email,
              decoration:
              const InputDecoration(labelText: "Correo Electrónico"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: "Contraseña"),
              obscureText: true,
            ),

            const SizedBox(height: 20),

            if (_isLoading)
              const CircularProgressIndicator()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CANCELAR"),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _registrarUsuario,
                    child: const Text("REGISTRAR"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
