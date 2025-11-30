import 'package:flutter/material.dart';
import 'package:dam_pfinal/main.dart';
import 'package:dam_pfinal/authentication/authentication.dart';
import 'package:dam_pfinal/modelo/guardia.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dam_pfinal/VentanaValidacion.dart';


class VentanaGuardia extends StatefulWidget {
  final String uid;

  const VentanaGuardia({super.key, required this.uid});

  @override
  State<VentanaGuardia> createState() => _VentanaGuardiaState();
}

class _VentanaGuardiaState extends State<VentanaGuardia> {
  int _selectedIndex = 0;


  Future<Guardia?> obtenerDatosDeGuardia(String uid) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('guardia').doc(uid).get();
      if (doc.exists) {
        return Guardia.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print("Error al obtener datos del guardia: $e");
    }
    return null;
  }


  static final List<Widget> _widgetOptions = <Widget>[
    dataUsuarios(),
    n1(),
    n2(),
    n3(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade300,
        title: const Text(
          "Guardia",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(100),
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map), label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_outlined), label: 'Alertas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_outlined), label: 'Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outlined), label: 'Guardias',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.indigo.shade300,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white70, unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // FutureBuilder adaptado para el modelo Guardia
            FutureBuilder<Guardia?>(
              // Llama a la nueva función
              future: obtenerDatosDeGuardia(widget.uid),
              builder: (context, snapshot) {
                // Casos de "cargando" y "error" siguen igual...
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return DrawerHeader(
                    decoration: BoxDecoration(color: Colors.indigo.shade300),
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return DrawerHeader(
                    decoration: BoxDecoration(color: Colors.indigo.shade300),
                    child: const Center(child: Text('Error al cargar perfil', style: TextStyle(color: Colors.white))),
                  );
                }

                // --- ¡Tenemos el objeto Guardia! ---
                var guardia = snapshot.data!; // Ahora esto es un objeto Guardia

                return DrawerHeader(
                  decoration: BoxDecoration(color: Colors.indigo.shade300),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 50, color: Colors.indigo),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        guardia.name, // <-- Usamos el objeto directamente: guardia.name
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        guardia.email, // <-- Usamos el objeto directamente: guardia.email
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // ============ INICIO DEL NUEVO CÓDIGO A PEGAR ============
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Validar Usuarios'),
              onTap: () {
                // Cierra el drawer primero
                Navigator.pop(context);
                // Navega a la nueva pantalla de validación
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PantallaValidar()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                _mostrarDialogoDeCierreSesion(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoDeCierreSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              // 1. La función se vuelve asíncrona
              onPressed: () async {
                // 2. Esperamos a que el Future de cerrarSesion() se complete
                await Auth().cerrarSesion();

                // 3. (Opcional pero recomendado) Verificamos si el contexto sigue activo
                if (!dialogContext.mounted) return;

                // 4. Navegamos DESPUÉS de que la sesión se haya cerrado
                Navigator.of(dialogContext).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => MyApp()),
                      (Route<dynamic> route) => false,
                );
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

}


Widget dataUsuarios() {
  return const Center(child: Text("Contenido de USUARIOS"));
}

Widget n1() {
  return const Center(child: Text("Contenido de N1"));
}

Widget n2() {
  return const Center(child: Text("Contenido de N2"));
}

Widget n3() {
  return const Center(child: Text("Contenido de N3"));
}