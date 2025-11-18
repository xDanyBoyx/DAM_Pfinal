import 'package:dam_pfinal/modelo/guardia.dart';
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


  @override
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
            onPressed: () {
              Auth().autenticacion(user.text, pass.text).then((men) {
                setState(() {
                  mensaje = men;
                });
              });
              pass.text = "";
              user.text = "";
            },
            child: Text("INGRESAR", style: TextStyle(fontSize: 20)),
            style: FilledButton.styleFrom(backgroundColor: Colors.blue),
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
                        content: Column(
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

                            Padding(
                              padding: EdgeInsetsGeometry.symmetric(
                                horizontal: 40,
                              ),
                              child: Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      var registroG = {
                                        'name': name.text,
                                        'edad': edad.text,
                                        'rango': rango.text,
                                        'email': user.text,
                                        'password': pass.text,
                                      };
                                      baseRemota.collection("guardia").add(registroG).then((value){
                                        setState(() {
                                          mensaje = "LA INSERSIÓN FUE EXITOSA";
                                        });
                                      });
                                      Auth().inscribir(user.text, pass.text).then((msg) {
                                        setState(() {
                                          mensaje = msg;
                                          Navigator.pop(context);
                                        });
                                      });
                                      Limpiar();
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
                        ),
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
    return Center(
      child: OutlinedButton(
        onPressed: () {
          Auth().cerrarSesion().then((x) {
            setState(() {
              mensaje = "";
            });
          });
        },
        child: Text("CERRAR SESIÓN"),
      ),
    );
  }

  Widget registros() {
    if (itemSeleccionado == "RESIDENTE") {
      return Column(children: [Text("EN ESPERA...")]);
    } else {
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

  Widget? Limpiar(){
    name.text = "";
    edad.text = "";
    rango.text = "";
    user.text = "";
    pass.text = "";
  }

}
