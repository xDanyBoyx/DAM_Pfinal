import 'package:flutter/material.dart';
import 'package:dam_pfinal/main.dart';
import 'package:dam_pfinal/authentication/authentication.dart';

class VentanaGuardia extends StatefulWidget {
  const VentanaGuardia({super.key});

  @override
  State<VentanaGuardia> createState() => _VentanaGuardiaState();
}

class _VentanaGuardiaState extends State<VentanaGuardia> {
  int _selectedIndex = 0;


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
        automaticallyImplyLeading: true,
        title: const Text(
          "Fraccionamiento",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade300,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map), label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_outlined), label: 'Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outlined), label: 'Guardias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apple), label: 'N3',
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
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.indigo.shade300,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.indigo.shade300,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Nombre del Usuario",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "usuario@email.com",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
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