import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dam_pfinal/main.dart';
import 'package:dam_pfinal/authentication/authentication.dart';
import 'package:dam_pfinal/controlador/basededatos.dart';
import 'package:dam_pfinal/modelo/aviso.dart';
import 'package:dam_pfinal/modelo/residente.dart';
import 'package:dam_pfinal/notification/notificaciones.dart';

class VentanaResidente extends StatefulWidget {
  final String uid;

  const VentanaResidente({super.key, required this.uid});

  @override
  State<VentanaResidente> createState() => _VentanaResidenteState();
}

class _VentanaResidenteState extends State<VentanaResidente> {
  late Future<Residente?> _residenteFuture;

  @override
  void initState() {
    super.initState();

    // Cargar datos del residente
    _residenteFuture = obtenerDatosDeResidente(widget.uid);

    // Inicializar notificaciones locales
    Notificaciones.init();

    // Registrar listener solo cuando el widget esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Notificaciones.escucharAvisos();
      }
    });
  }

  Future<Residente?> obtenerDatosDeResidente(String uid) async {
    try {
      DocumentSnapshot doc =
      await FirebaseFirestore.instance.collection('residente').doc(uid).get();
      if (doc.exists) {
        return Residente.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print("Error al obtener datos del residente: $e");
    }
    return null;
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

  Widget _avisoCard(Aviso aviso) {
    final String fechaFormato =
        '${aviso.fecha.day.toString().padLeft(2, '0')}/${aviso.fecha.month.toString().padLeft(2, '0')}/${aviso.fecha.year} '
        '${aviso.fecha.hour.toString().padLeft(2, '0')}:${aviso.fecha.minute.toString().padLeft(2, '0')}';

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

  Widget _pantallaHistorial() {
    return const Center(
        child: Text("Pantalla de Historial de Alertas (Tarea R-3)",
            style: TextStyle(fontSize: 18)));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            "MI FRACCIONAMIENTO",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.indigo.shade300,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Cerrar sesión',
              onPressed: () => _mostrarDialogoDeCierreSesion(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "AVISOS", icon: Icon(Icons.campaign)),
              Tab(text: "HISTORIAL", icon: Icon(Icons.history)),
            ],
            labelStyle: TextStyle(color: Colors.red, fontSize: 16),
            unselectedLabelStyle: TextStyle(color: Colors.white, fontSize: 12),
            indicatorWeight: 5,
          ),
        ),
        body: TabBarView(
          children: [
            _pantallaAvisos(),
            _pantallaHistorial(),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              FutureBuilder<Residente?>(
                future: _residenteFuture,
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
                          residente.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          residente.email,
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
}
