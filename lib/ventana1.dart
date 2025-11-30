import 'package:flutter/material.dart';
// Importaciones necesarias de tu trabajo (Avisos)
import 'package:dam_pfinal/controlador/basededatos.dart';
import 'package:dam_pfinal/modelo/aviso.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Importaciones necesarias del trabajo de tus compañeros (Perfil y Login)
import 'package:dam_pfinal/main.dart';
import 'package:dam_pfinal/authentication/authentication.dart';
import 'package:dam_pfinal/modelo/guardia.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dam_pfinal/VentanaValidacion.dart';


class VentanaGuardia extends StatefulWidget {
  // Se añade el UID, necesario para cargar los datos del Drawer
  final String uid;

  const VentanaGuardia({super.key, required this.uid});

  @override
  State<VentanaGuardia> createState() => _VentanaGuardiaState();
}

class _VentanaGuardiaState extends State<VentanaGuardia> {
  int _selectedIndex = 0;
  // Controladores para el módulo de Avisos (Tu trabajo)
  final tituloController = TextEditingController();
  final contenidoController = TextEditingController();

  // Función para obtener los datos del Guardia (Trabajo de compañeros)
  Future<Guardia?> obtenerDatosDeGuardia(String uid) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('guardia').doc(uid).get();
      if (doc.exists) {
        // Asumiendo que el modelo Guardia tiene un factory constructor fromFirestore
        return Guardia.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print("Error al obtener datos del guardia: $e");
    }
    return null;
  }

  // Se define la lista de opciones de widgets, incluyendo tu módulo de Avisos
  late final List<Widget> _widgetOptions = <Widget>[
    dataUsuarios(),           // 0. Mapa/Usuarios
    n1(),                     // 1. Incidencias
    n2(),                     // 2. Alertas/Reportes
    _pantallaGestionAvisos(), // 3. Avisos (Tu Módulo G-6, G-7)
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

      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),

      // BottomNavigationBar unificado (4 ítems, incluyendo Avisos)
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map), label: 'Mapa', // Manteniendo el label general
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_outlined), label: 'Incidencias', // Módulo 1
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_outlined), label: 'Alertas', // Módulo 2
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign), label: 'Avisos', // Tu Módulo
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.indigo.shade300,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white70, unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
      ),

      // Drawer unificado (Perfil del Guardia y Navegación)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // FutureBuilder para cargar los datos del Guardia
            FutureBuilder<Guardia?>(
              future: obtenerDatosDeGuardia(widget.uid),
              builder: (context, snapshot) {
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

                var guardia = snapshot.data!;

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
                        guardia.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        guardia.email,
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

            // Opción de Validar Usuarios (Trabajo de compañeros)
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Validar Usuarios'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PantallaValidar()),
                );
              },
            ),
            const Divider(),

            // Opción de Cerrar Sesión
            ListTile(
              leading: const Icon(Icons.logout),
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

  // G-6: Función para crear un nuevo aviso (Tu trabajo)
  Future<void> _enviarAviso() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: Usuario no autenticado");
      return;
    }

    final nuevoAviso = Aviso(
      titulo: tituloController.text.trim(),
      contenido: contenidoController.text.trim(),
      creadoPor: user.email!,
      fecha: DateTime.now(),
    );

    String resultado = await DB.crearAviso(nuevoAviso);

    if (resultado == "ok") {
      tituloController.clear();
      contenidoController.clear();
      setState(() {});
      print("Aviso creado exitosamente.");
    } else {
      print("Error al crear el aviso: $resultado");
    }
  }

  // G-7: Lógica para eliminar el aviso (Tu trabajo)
  Future<void> _eliminarAviso(Aviso aviso) async {
    String resultado = await DB.eliminarAviso(aviso.id);
    if (resultado == "ok") {
      setState(() {});
      print("Aviso ${aviso.titulo} eliminado.");
    } else {
      print("Error al eliminar aviso: $resultado");
    }
  }

  // G-7: Lógica para mostrar y manejar el diálogo de edición (Tu trabajo)
  Future<void> _mostrarDialogoEdicion(BuildContext context, Aviso aviso) async {
    final editTituloController = TextEditingController(text: aviso.titulo);
    final editContenidoController = TextEditingController(text: aviso.contenido);

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Editar Aviso'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: editTituloController,
                  decoration: const InputDecoration(labelText: "Título"),
                ),
                TextField(
                  controller: editContenidoController,
                  decoration: const InputDecoration(labelText: "Contenido"),
                  maxLines: 4,
                  minLines: 2,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final avisoModificado = Aviso(
                  id: aviso.id,
                  titulo: editTituloController.text.trim(),
                  contenido: editContenidoController.text.trim(),
                  creadoPor: aviso.creadoPor,
                  fecha: aviso.fecha,
                );

                String resultado = await DB.actualizarAviso(avisoModificado);
                if (resultado == "ok") {
                  setState(() {});
                  print("Aviso ${aviso.titulo} actualizado.");
                } else {
                  print("Error al actualizar: $resultado");
                }
              },
            ),
          ],
        );
      },
    );
  }

  // G-7: Diseño de la tarjeta de gestión (Tu trabajo)
  Widget _avisoCardGestion(Aviso aviso) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10.0),
      elevation: 2.0,
      child: ListTile(
        title: Text(aviso.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          aviso.contenido,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _mostrarDialogoEdicion(context, aviso),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _eliminarAviso(aviso),
            ),
          ],
        ),
      ),
    );
  }

  // G-6, G-7: Pantalla de Gestión de Avisos (Tu trabajo)
  Widget _pantallaGestionAvisos() {
    return FutureBuilder<List<Aviso>>(
      future: DB.mostrarAvisos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final avisos = snapshot.data ?? [];

        return Column(
          children: [
            // Formulario de Creación
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Crear Nuevo Aviso", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo.shade800)),
                  const SizedBox(height: 15),
                  TextField(controller: tituloController, decoration: const InputDecoration(labelText: "Título")),
                  const SizedBox(height: 10),
                  TextField(controller: contenidoController, decoration: const InputDecoration(labelText: "Contenido"), maxLines: 3),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (tituloController.text.isNotEmpty && contenidoController.text.isNotEmpty) {
                        _enviarAviso();
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text("PUBLICAR AVISO"),
                  ),
                  const Divider(height: 30),
                ],
              ),
            ),

            // Lista de Gestión (Lectura, Edición, Eliminación)
            Expanded(
              child: avisos.isEmpty
                  ? const Center(child: Text('No hay avisos publicados para gestionar.'))
                  : ListView.builder(
                itemCount: avisos.length,
                itemBuilder: (context, index) {
                  return _avisoCardGestion(avisos[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Función de cierre de sesión (Unificada)
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
              onPressed: () async {
                await Auth().cerrarSesion();
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MyApp()),
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

// Estos widgets son los placeholders
Widget dataUsuarios() {
  return const Center(child: Text("Contenido de USUARIOS (Mapa)"));
}

Widget n1() {
  return const Center(child: Text("Contenido de INCIDENCIAS"));
}

Widget n2() {
  return const Center(child: Text("Contenido de ALERTAS"));
}