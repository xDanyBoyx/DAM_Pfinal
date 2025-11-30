import 'package:dam_pfinal/modelo/guardia.dart';
import 'package:dam_pfinal/ventana1.dart';
import 'package:dam_pfinal/ventana2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'authentication/authentication.dart';
import 'controlador/basededatos.dart';
import 'formulario_registro.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
    // Muestra la pantalla de Login.
    if (!Auth().estaAutenticado()) {
      return ListView(
        padding: const EdgeInsets.all(30),
        children: [
          const SizedBox(height: 40),

          const SizedBox(height: 100),
          Image.asset("assets/fondologo1.png",
            width: 250,
            height: 250,
          ),
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

          // --- BOTÓN DE INGRESAR ---
          FilledButton(
            onPressed: () async {
              try {
                // 1. Intenta autenticar al usuario
                String respuesta = await Auth().autenticacion(user.text, pass.text);

                // 2. Si la autenticación es exitosa...
                if (respuesta == "ok") {
                  String? uid = Auth().microServicio.currentUser?.uid;
                  if (uid != null) {
                    // 3. ...llama a la función maestra para determinar el rol.
                    await determinarRolUsuario(uid);
                  } else {
                    setState(() {
                      mensaje = "No se pudo obtener el ID de usuario tras el login.";
                    });
                  }
                } else {
                  // Si la autenticación falla, muestra el mensaje de error de Firebase.
                  setState(() {
                    mensaje = respuesta;
                  });
                }
              } catch (e) {
                // Captura cualquier otro error inesperado durante el proceso.
                setState(() {
                  mensaje = "Ocurrió un error inesperado: $e";
                });
              }
            },
            child: const Text("INGRESAR", style: TextStyle(fontSize: 20)),
          ),

          // --- BOTÓN DE REGISTRO (CORREGIDO) ---
          TextButton(
            onPressed: () async {
              // Limpia los controladores de login ANTES de abrir el diálogo.
              // La función Limpiar() original ya no es necesaria aquí.
              user.clear();
              pass.clear();
              setState(() {
                mensaje = ""; // Limpia mensajes de error antiguos
              });

              // Muestra el diálogo que contiene nuestro nuevo formulario aislado.
              final registroExitoso = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Registro de Usuario"),
                    contentPadding: const EdgeInsets.all(0), // El padding ya está en el formulario
                    content: const FormularioRegistro(), // <-- ¡AQUÍ ESTÁ LA MAGIA!
                    // Nota: Ya no hay 'actions' aquí, los botones están dentro de FormularioRegistro
                  );
                },
              );

              // Si el formulario nos devolvió 'true', significa que el registro fue exitoso.
              if (registroExitoso == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("¡REGISTRO EXITOSO! Espera la validación del administrador.")),
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

    // --- CASO 2: El usuario SÍ está autenticado ---
    // Si el tipo de usuario ya se determinó, muestra la pantalla correspondiente.

    if (tipoUsuario == "guardia") {
      String? uid = Auth().microServicio.currentUser?.uid;
      if (uid != null) {
        return VentanaGuardia(uid: uid);
      }
    }

    if (tipoUsuario == "residente") {
      String? uid = Auth().microServicio.currentUser?.uid;
      if (uid != null) {
        return ventanaResidente(uid: uid);
      }
    }

    // --- CASO 3: Usuario autenticado pero AÚN NO se determina el rol ---
    // Muestra un indicador de carga mientras `determinarRolUsuario` trabaja.
    return const Center(child: CircularProgressIndicator());
  }


  Future<void> _determinarSesionInicial() async {
    if (Auth().estaAutenticado()) {
      String? uid = Auth().microServicio.currentUser?.uid;
      if (uid != null) {
        await determinarRolUsuario(uid);
      }
    }
  }

  Future<void> determinarRolUsuario(String uid) async {
    // 1. Buscar primero en la colección "guardia"
    var docGuardia = await baseRemota.collection("guardia").doc(uid).get();
    if (docGuardia.exists) {
      if (docGuardia.data()?['active'] == true) {
        setState(() {
          tipoUsuario = "guardia";
        });
      } else {
        setState(() {
          mensaje = "Tu cuenta de guardia está pendiente de activación.";
          Auth().cerrarSesion();
        });
      }
      return;
    }

    // 2. Si no es guardia, buscar en la colección "residente"
    var docResidente = await baseRemota.collection("residente").doc(uid).get();
    if (docResidente.exists) {
      if (docResidente.data()?['active'] == true) {
        setState(() {
          tipoUsuario = "residente";
        });
      } else {
        setState(() {
          mensaje = "Tu cuenta de residente está pendiente de activación.";
          Auth().cerrarSesion();
        });
      }
      return;
    }

    // 3. Si no se encontró en ninguna colección
    setState(() {
      mensaje = "Error: Perfil no encontrado en la base de datos.";
      Auth().cerrarSesion();
    });
  }
}
