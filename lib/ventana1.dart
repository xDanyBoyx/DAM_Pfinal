import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dam_pfinal/pantalla_lista_guardias.dart';
import 'package:dam_pfinal/controlador/basededatos.dart';
import 'package:dam_pfinal/modelo/incidencias.dart';
import 'package:dam_pfinal/mapa_screen_guardia.dart';
import 'package:dam_pfinal/incidencia_detalle_screen.dart';
import 'package:dam_pfinal/modelo/aviso.dart';
import 'package:dam_pfinal/main.dart';
import 'package:dam_pfinal/authentication/authentication.dart';
import 'package:dam_pfinal/modelo/guardia.dart';
import 'package:dam_pfinal/VentanaValidacion.dart';

import 'notification/notificaciones.dart'; // Asegúrate de importar tu clase Notificaciones

class VentanaGuardia extends StatefulWidget {
  final String uid;

  const VentanaGuardia({super.key, required this.uid});

  @override
  State<VentanaGuardia> createState() => _VentanaGuardiaState();
}

class _VentanaGuardiaState extends State<VentanaGuardia> {
  int _selectedIndex = 0;
  late Future<List<Incidencia>> _incidenciasFuture;
  final tituloController = TextEditingController();
  final contenidoController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Inicializa tu Future de Incidencias
    _incidenciasFuture = DB.mostrarIncidenciasPendientes();

    // Inicializa el plugin de notificaciones
    Notificaciones.init();

    // Escucha los avisos en tiempo real
    Notificaciones.escucharAvisos();
  }

  Future<Guardia?> obtenerDatosDeGuardia(String uid) async {
    try {
      DocumentSnapshot doc =
      await FirebaseFirestore.instance.collection('guardia').doc(uid).get();
      if (doc.exists) {
        return Guardia.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print("Error al obtener datos del guardia: $e");
    }
    return null;
  }

  late final List<Widget> _widgetOptions = <Widget>[
    const GuardiaMapaScreen(),
    _listaIncidencias(),
    n2(),
    _pantallaGestionAvisos(),
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
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(
              icon: Icon(Icons.access_time_outlined), label: 'Incidencias'),
          BottomNavigationBarItem(
              icon: Icon(Icons.report_outlined), label: 'Alertas'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Avisos'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.indigo.shade300,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white70,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            FutureBuilder<Guardia?>(
              future: obtenerDatosDeGuardia(widget.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return DrawerHeader(
                    decoration: BoxDecoration(color: Colors.indigo.shade300),
                    child: const Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return DrawerHeader(
                    decoration: BoxDecoration(color: Colors.indigo.shade300),
                    child: const Center(
                        child: Text('Error al cargar perfil',
                            style: TextStyle(color: Colors.white))),
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
                            fontSize: 16),
                      ),
                      Text(
                        guardia.email,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
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
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Ver Personal de Guardia'),
              onTap: () async {
                Guardia? guardiaActual =
                await obtenerDatosDeGuardia(widget.uid);
                if (guardiaActual == null) return;
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PantallaListaGuardias(guardiaActual: guardiaActual),
                  ),
                );
              },
            ),
            const Divider(),
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

  // --- Incidencias ---
  Widget _listaIncidencias() {
    return FutureBuilder(
      future: _incidenciasFuture,
      builder: (context, AsyncSnapshot<List<Incidencia>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text("Error al cargar incidencias: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text("No hay incidencias pendientes o en curso."));
        }
        final incidencias = snapshot.data!;
        return ListView.builder(
          itemCount: incidencias.length,
          itemBuilder: (context, index) {
            final incidencia = incidencias[index];
            final color = incidencia.estado == 'Pendiente'
                ? Colors.red.shade600
                : Colors.orange.shade600;
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color,
                  child: const Icon(Icons.warning, color: Colors.white),
                ),
                title: Text('Alerta de Residente: ${incidencia.nombreResidente}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'Detalles: ${incidencia.detalles ?? 'No proporcionados'}\nEstado: ${incidencia.estado}\nHora: ${incidencia.timestamp.toDate().toLocal().toString().substring(11, 19)}'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            IncidenciaDetalleScreen(incidencia: incidencia)),
                  );
                  if (result == true) {
                    setState(() {
                      _incidenciasFuture = DB.mostrarIncidenciasPendientes();
                    });
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  // --- Avisos ---
  Future<void> _enviarAviso() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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

  Future<void> _eliminarAviso(Aviso aviso) async {
    String resultado = await DB.eliminarAviso(aviso.id);
    if (resultado == "ok") {
      setState(() {});
      print("Aviso ${aviso.titulo} eliminado.");
    } else {
      print("Error al eliminar aviso: $resultado");
    }
  }

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

// --- Avisos ---
  Widget _pantallaGestionAvisos() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('avisos').orderBy('fecha', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar avisos: ${snapshot.error}'));
        }

        // Convertimos los documentos a objetos Aviso
        final avisos = snapshot.data?.docs
            .map((doc) => Aviso.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList() ??
            [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Crear Nuevo Aviso",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800)),
                  const SizedBox(height: 15),
                  TextField(
                      controller: tituloController,
                      decoration: const InputDecoration(labelText: "Título")),
                  const SizedBox(height: 10),
                  TextField(
                    controller: contenidoController,
                    decoration: const InputDecoration(labelText: "Contenido"),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (tituloController.text.isNotEmpty &&
                          contenidoController.text.isNotEmpty) {
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

Widget n2() {
  return const Center(child: Text("Contenido de ALERTAS/REPORTES"));
}
