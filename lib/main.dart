import 'package:dam_pfinal/modelo/guardia.dart';
import 'package:dam_pfinal/ventana1.dart';
import 'package:dam_pfinal/ventana2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'authentication/authentication.dart';
import 'controlador/basededatos.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: MyApp(), debugShowCheckedModeBanner: false));
}

List<String> registro = ["RESIDENTE", "GUARDIA"];

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String mensaje = "";
  final user = TextEditingController();
  final pass = TextEditingController();
  List<Guardia> userG = [];
  String itemSeleccionado = registro.first;
  final name = TextEditingController();
  final edad = TextEditingController();
  final rango = TextEditingController();
  final calle = TextEditingController();
  final colonia = TextEditingController();
  final noInt = TextEditingController();
  bool register = false;
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
    if (!Auth().estaAutenticado()) {
      return ListView(
        padding: EdgeInsets.all(30),
        children: [
          SizedBox(height: 40),
          Text(
            "MI FRACCIONAMIENTO SEGURO",
            style: TextStyle(fontSize: 30, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 50),
          Icon(Icons.shield, size: 150, color: Color(0xFF1E1E46)),
          SizedBox(height: 20),
          TextField(
            controller: user,
            decoration: InputDecoration(
              labelText: "EMAIL",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 30),
          TextField(
            controller: pass,
            decoration: InputDecoration(
              labelText: "CONTRASEÑA",
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          SizedBox(height: 40),
          FilledButton(
            onPressed: () async {
              String respuesta = await Auth().autenticacion(
                user.text,
                pass.text,
              );
              if (respuesta == "ok") {
                String correo = user.text;
                var guardia = await baseRemota
                    .collection("guardia")
                    .where("email", isEqualTo: correo)
                    .get();
                if (guardia.docs.isNotEmpty) {
                  bool activo = guardia.docs.first["active"];
                  if (!activo) {
                    setState(() {
                      mensaje = "AÚN NO HAS SIDO VALIDADO POR UN GUARDIA";
                    });
                    return;
                  }
                  setState(() {
                    tipoUsuario = "guardia";
                  });
                  //setState(() {});
                  return;
                }
                var residente = await baseRemota
                    .collection("residente")
                    .where("email", isEqualTo: correo)
                    .get();
                if (residente.docs.isNotEmpty) {
                  bool activo = residente.docs.first["active"];
                  if (!activo) {
                    setState(() {
                      mensaje = "AÚN NO HAS SIDO VALIDADO POR UN GUARDIA";
                    });
                    return;
                  }
                  setState(() {
                    tipoUsuario = "residente";
                  });
                  //setState(() {});
                  return;
                }
                setState(() {
                  mensaje = "USUARIO NO ENCONTRADO";
                });
              } else {
                setState(() {
                  mensaje = respuesta;
                });
              }
              //user.clear();
              //pass.clear();
            },
            child: Text("INGRESAR", style: TextStyle(fontSize: 20)),
          ),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setStateDialog) {
                      return AlertDialog(
                        title: Text(
                          "Registro de usuario",
                          style: TextStyle(fontSize: 30),
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButtonFormField(
                                items: registro.map((e) {
                                  return DropdownMenuItem(
                                    child: Text(e),
                                    value: e,
                                  );
                                }).toList(),
                                initialValue: itemSeleccionado,
                                onChanged: (x) {
                                  setStateDialog(() {
                                    itemSeleccionado = x.toString();
                                  });
                                },
                              ),

                              SizedBox(height: 20),

                              registros(),
                            ],
                          ),
                        ),
                        actions: [
                          Padding(
                            padding: EdgeInsetsGeometry.symmetric(
                              horizontal: 40,
                            ),
                            child: Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    if (register == true) {
                                      var registroR = {
                                        'name': name.text,
                                        'edad': int.parse(edad.text),
                                        'domicilio': {
                                          'calle': calle.text,
                                          'colonia': colonia.text,
                                          'noInt': noInt.text,
                                        },
                                        'email': user.text,
                                        'password': pass.text,
                                      };
                                      baseRemota
                                          .collection("residente")
                                          .add(registroR)
                                          .then((value) {
                                            setState(() {
                                              mensaje =
                                                  "ESPERA LA VALIDACIÓN DEL GUARDIA";
                                            });
                                          });
                                      Limpiar();
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            mensaje,
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      );
                                    } else {
                                      baseRemota.collection("guardia").get().then((
                                        query,
                                      ) {
                                        bool noHayGuardias = query.docs.isEmpty;

                                        var registroG = {
                                          'name': name.text,
                                          'edad': int.parse(edad.text),
                                          'rango': rango.text,
                                          'email': user.text,
                                          'password': pass.text,
                                          'active': noHayGuardias
                                              ? true
                                              : false,
                                        };

                                        if (noHayGuardias) {
                                          baseRemota
                                              .collection("guardia")
                                              .add(registroG)
                                              .then((value) {
                                                setState(() {
                                                  mensaje =
                                                      "LA INSERSIÓN FUE EXITOSA";
                                                });
                                              });

                                          Auth()
                                              .inscribir(user.text, pass.text)
                                              .then((msg) {
                                                setState(() {
                                                  Navigator.pop(context);
                                                  Limpiar();
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        mensaje,
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                });
                                              });
                                        } else {
                                          baseRemota
                                              .collection("guardia")
                                              .add(registroG)
                                              .then((value) {
                                                setState(() {
                                                  mensaje =
                                                      "LA INSERSIÓN FUE EXITOSA";
                                                });
                                              });

                                          Navigator.pop(context);
                                          Limpiar();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "ESPERA LA VALIDACIÓN DEL GUARDIA",
                                                style: TextStyle(fontSize: 20),
                                              ),
                                            ),
                                          );
                                        }
                                      });
                                    }
                                  },
                                  child: Text("REGISTRAR"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      Navigator.pop(context);
                                    });
                                  },
                                  child: Text("CANCELAR"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
            child: Text(
              "CREAR USUARIO NUEVO",
              style: TextStyle(color: Colors.blueAccent, fontSize: 15),
            ),
          ),
          Text(mensaje, textAlign: TextAlign.center),
        ],
      );
    }
    if (tipoUsuario == "guardia") {
      return VentanaGuardia();
    } else if (tipoUsuario == "residente") {
      return VentanaResidente();
    }
    ;
    return Center(
      child:
      OutlinedButton(onPressed: (){
        Auth().cerrarSesion().then((x){
          setState(() {
            mensaje = "SALISTE LOGIN";
          });
        });
      },
          child: Text("CERRAR SESIÓN")),
    );
  }

  Widget registros() {
    if (itemSeleccionado == "RESIDENTE") {
      Limpiar();
      register = true;
      return Column(
        children: [
          TextField(
            controller: name,
            decoration: InputDecoration(
              labelText: "NOMBRE",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 40),
          TextField(
            controller: edad,
            decoration: InputDecoration(
              labelText: "EDAD",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 40),
          TextField(
            controller: calle,
            decoration: InputDecoration(
              labelText: "CALLE",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 40),
          TextField(
            controller: colonia,
            decoration: InputDecoration(
              labelText: "COLONIA",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 40),
          TextField(
            controller: noInt,
            decoration: InputDecoration(
              labelText: "No. de Casa",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 40),
          TextField(
            controller: user,
            decoration: InputDecoration(
              labelText: "CORREO",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 40),
          TextField(
            controller: pass,
            decoration: InputDecoration(
              labelText: "CONTRASEÑA",
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          SizedBox(height: 40),
        ],
      );
    } else {
      Limpiar();
      register = false;
      return Column(
        children: [
          TextField(
            controller: name,
            decoration: InputDecoration(
              labelText: "NOMBRE",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 40),
          TextField(
            controller: edad,
            decoration: InputDecoration(
              labelText: "EDAD",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 40),
          TextField(
            controller: rango,
            decoration: InputDecoration(
              labelText: "RANGO",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 40),
          TextField(
            controller: user,
            decoration: InputDecoration(
              labelText: "EMAIL",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 40),
          TextField(
            controller: pass,
            decoration: InputDecoration(
              labelText: "CONTRASEÑA",
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          SizedBox(height: 40),
        ],
      );
    }
  }

  Widget? Limpiar() {
    name.text = "";
    edad.text = "";
    rango.text = "";
    user.text = "";
    pass.text = "";
    calle.text = "";
    colonia.text = "";
    noInt.text = "";
  }

  Future<void> _determinarSesionInicial() async {
    if (Auth().estaAutenticado()) {

      String correo = FirebaseAuth.instance.currentUser!.email!;

      var guardia = await baseRemota
          .collection("guardia")
          .where("email", isEqualTo: correo)
          .get();

      if (guardia.docs.isNotEmpty) {
        bool activo = guardia.docs.first["active"];
        if (activo) {
          setState(() => tipoUsuario = "guardia");
          return;
        }
      }

      var residente = await baseRemota
          .collection("residente")
          .where("email", isEqualTo: correo)
          .get();

      if (residente.docs.isNotEmpty) {
        bool activo = residente.docs.first["active"];
        if (activo) {
          setState(() => tipoUsuario = "residente");
          return;
        }
      }

      // Si está autenticado pero no activo → cerrar sesión
      await Auth().cerrarSesion();
    }
  }

}
