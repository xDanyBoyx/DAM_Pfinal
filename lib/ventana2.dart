import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dam_pfinal/main.dart';
import 'package:dam_pfinal/authentication/authentication.dart';
import 'package:dam_pfinal/controlador/basededatos.dart';
import 'package:dam_pfinal/modelo/aviso.dart';
import 'package:dam_pfinal/modelo/residente.dart';

// El nombre de la clase se mantiene como VentanaResidente y ahora requiere el UID
class VentanaResidente extends StatefulWidget {
  final String uid;

  const VentanaResidente({super.key, required this.uid});

  @override
  State<VentanaResidente> createState() => _VentanaResidenteState();
}

class _VentanaResidenteState extends State<VentanaResidente> {

  // Función agregada por el equipo para obtener los datos del Residente logueado
  Future<Residente?> obtenerDatosDeResidente(String uid) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('residente').doc(uid).get();
      if (doc.exists) {
        // Asumiendo que el modelo Residente tiene un factory constructor fromFirestore
        return Residente.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print("Error al obtener datos del residente: $e");
    }
    return null;
  }

  // Función de cierre de sesión
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

  @override
  Widget build(BuildContext context) {
    // Se mantiene el DefaultTabController para tu módulo R-4 (Avisos)
    return DefaultTabController(
      length: 2, // Avisos y Historial
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            "MI FRACCIONAMIENTO",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.indigo.shade300,
          bottom: const TabBar(
            tabs: [
              Tab(text: "AVISOS", icon: Icon(Icons.campaign)), // Tu módulo R-4
              Tab(text: "HISTORIAL", icon: Icon(Icons.history)), // Tarea R-3
            ],
            labelStyle: TextStyle(color: Colors.red, fontSize: 16),
            unselectedLabelStyle: TextStyle(color: Colors.white, fontSize: 12),
            indicatorWeight: 5,
          ),
        ),

        body: TabBarView(
          children: [
            _pantallaAvisos(), // Tu implementación R-4: Lectura de Avisos
            _pantallaHistorial(), // Placeholder para R-3
          ],
        ),

        // Drawer integrado desde la versión remota
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // FutureBuilder para cargar los datos del Residente
              FutureBuilder<Residente?>(
                future: obtenerDatosDeResidente(widget.uid),
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

                  var residente = snapshot.data!;

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
                          residente.name, // Usando el objeto Residente
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          residente.email, // Usando el objeto Residente
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
      ),
    );
  }

  // R-4: Diseño para mostrar un Aviso individual en un Card
  Widget _avisoCard(Aviso aviso) {
    // Formato de fecha para que se vea legible
    final String fechaFormato = '${aviso.fecha.day.toString().padLeft(2, '0')}/${aviso.fecha.month.toString().padLeft(2, '0')}/${aviso.fecha.year} ${aviso.fecha.hour.toString().padLeft(2, '0')}:${aviso.fecha.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 15.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              aviso.titulo,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade800,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              aviso.contenido,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 15),

            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Publicado por: ${aviso.creadoPor.split('@').first}',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
                Text(
                  fechaFormato,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // R-4: Pantalla para mostrar la lista de Avisos (FutureBuilder para la BD)
  Widget _pantallaAvisos() {
    return FutureBuilder<List<Aviso>>(
      future: DB.mostrarAvisos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar avisos: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay avisos generales publicados.'));
        }

        final avisos = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(10.0),
          itemCount: avisos.length,
          itemBuilder: (context, index) {
            return _avisoCard(avisos[index]);
          },
        );
      },
    );
  }

  // R-3: Placeholder para la tarea de Diego (Historial de Alertas)
  Widget _pantallaHistorial() {
    return const Center(child: Text("Pantalla de Historial de Alertas (Tarea R-3)", style: TextStyle(fontSize: 18)));
  }
}