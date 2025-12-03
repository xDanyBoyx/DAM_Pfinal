import 'package:dam_pfinal/modelo/guardia.dart';
import 'package:dam_pfinal/ventana1.dart';
import 'package:dam_pfinal/ventana2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'authentication/authentication.dart';
import 'controlador/basededatos.dart';
import 'formulario_registro.dart';
import 'notification/notificaciones.dart';
import 'residente_nuevo_reporte.dart';

//LLAMADA DE CLASE A EJECUTAR
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Inicializamos las notificaciones
  await Notificaciones.init();

  runApp(MaterialApp(home: MyApp(), debugShowCheckedModeBanner: false));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String mensaje = "";
  final user = TextEditingController();
  final pass = TextEditingController();

  String tipoUsuario = "";

  @override
  void initState() {
    super.initState();
    _determinarSesionInicial();

    // --- INICIAMOS EL LISTENER DE NOTIFICACIONES ---
    Notificaciones.escucharAvisos();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey, Colors.white, Colors.blueGrey],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: validar(),
      ),
    );
  }

  Widget validar() {
    // --- CASO 1: El usuario NO está autenticado ---
    if (!Auth().estaAutenticado()) {
      return ListView(
        padding: const EdgeInsets.all(30),
        children: [
          const SizedBox(height: 40),
          const SizedBox(height: 100),
          Image.asset("assets/fondologo1.png", width: 250, height: 250),
          const SizedBox(height: 50),
          TextField(
            controller: user,
            decoration: const InputDecoration(
              labelText: "EMAIL",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: pass,
            decoration: const InputDecoration(
              labelText: "CONTRASEÑA",
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 40),
          FilledButton(
            onPressed: () async {
              try {
                String respuesta = await Auth().autenticacion(user.text, pass.text);
                if (respuesta == "ok") {
                  String? uid = Auth().microServicio.currentUser?.uid;
                  if (uid != null) {
                    await determinarRolUsuario(uid);
                  } else {
                    setState(() {
                      mensaje = "No se pudo obtener el ID de usuario tras el login.";
                    });
                  }
                } else {
                  setState(() {
                    mensaje = respuesta;
                  });
                }
              } catch (e) {
                setState(() {
                  mensaje = "Ocurrió un error inesperado: $e";
                });
              }
            },
            child: const Text("INGRESAR", style: TextStyle(fontSize: 20)),
          ),
          TextButton(
            onPressed: () async {
              user.clear();
              pass.clear();
              setState(() { mensaje = ""; });

              final registroExitoso = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Registro de Usuario"),
                    contentPadding: const EdgeInsets.all(0),
                    content: const FormularioRegistro(),
                  );
                },
              );

              if (registroExitoso == true && context.mounted) {
                setState(() {
                  tipoUsuario = "";
                  mensaje = "";
                });
                await Auth().cerrarSesion();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("¡REGISTRO EXITOSO! Espera la validación del administrador."))
                );
              }
            },
            child: const Text(
              "CREAR USUARIO NUEVO",
              style: TextStyle(color: Colors.blueAccent, fontSize: 15),
            ),
          ),
          if (mensaje.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
        ],
      );
    }

    // --- CASO 2: Usuario autenticado ---
    if (tipoUsuario == "guardia") {
      String? uid = Auth().microServicio.currentUser?.uid;
      if (uid != null) return VentanaGuardia(uid: uid);
    }

    if (tipoUsuario == "residente") {
      String? uid = Auth().microServicio.currentUser?.uid;
      if (uid != null) return VentanaResidente(uid: uid);
    }

    // --- CASO 3: Usuario autenticado pero aún no se determina el rol ---
    return const Center(child: CircularProgressIndicator());
  }

  Future<void> _determinarSesionInicial() async {
    if (Auth().estaAutenticado()) {
      String? uid = Auth().microServicio.currentUser?.uid;
      if (uid != null) await determinarRolUsuario(uid);
    }
  }

  Future<void> determinarRolUsuario(String uid) async {
    var docGuardia = await baseRemota.collection("guardia").doc(uid).get();
    if (docGuardia.exists) {
      if (docGuardia.data()?['active'] == true) {
        setState(() { tipoUsuario = "guardia"; });
      } else {
        setState(() {
          mensaje = "Tu cuenta de guardia está pendiente de activación.";
          Auth().cerrarSesion();
        });
      }
      return;
    }

    var docResidente = await baseRemota.collection("residente").doc(uid).get();
    if (docResidente.exists) {
      if (docResidente.data()?['active'] == true) {
        setState(() { tipoUsuario = "residente"; });
      } else {
        setState(() {
          mensaje = "Tu cuenta de residente está pendiente de activación.";
          Auth().cerrarSesion();
        });
      }
      return;
    }

    setState(() {
      mensaje = "Error: Perfil no encontrado en la base de datos.";
      Auth().cerrarSesion();
    });
  }
}
