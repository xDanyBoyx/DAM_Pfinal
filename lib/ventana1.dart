import 'package:flutter/material.dart';
import 'package:dam_pfinal/controlador/basededatos.dart';
import 'package:dam_pfinal/modelo/incidencias.dart';
import 'package:dam_pfinal/mapa_screen_guardia.dart';
import 'package:dam_pfinal/incidencia_detalle_screen.dart';


class VentanaGuardia extends StatefulWidget {
  const VentanaGuardia({super.key});

  @override
  State<VentanaGuardia> createState() => _VentanaGuardiaState();
}

class _VentanaGuardiaState extends State<VentanaGuardia> {

  late Future<List<Incidencia>> _incidenciasFuture;

  @override
  void initState() {
    super.initState();
    _incidenciasFuture = DB.mostrarIncidenciasPendientes();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: const Text(
            "MI FRACCIONAMIENTO",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.indigo.shade300,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Mapa", icon: Icon(Icons.map)),
              Tab(text: "Incidencias", icon: Icon(Icons.access_time_outlined)),
              Tab(text: "N2", icon: Icon(Icons.edit_note_outlined)),
              Tab(text: "N3", icon: Icon(Icons.apple)),
            ],
            labelStyle: TextStyle(color: Colors.red, fontSize: 16),
            unselectedLabelStyle: TextStyle(color: Colors.white, fontSize: 12),
            indicatorWeight: 5,
          ),
        ),
        body: TabBarView(
          children: [
            const GuardiaMapaScreen(),
            listaIncidencias(),
            n2(),
            n3(),
          ],
        ),
        drawer: const Drawer(
        ),
      ),
    );
  }

  Widget listaIncidencias(){
    return FutureBuilder(
      future: _incidenciasFuture,
      builder: (context, AsyncSnapshot<List<Incidencia>> snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error al cargar incidencias: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No hay incidencias pendientes o en curso."));
        }

        final incidencias = snapshot.data!;
        return ListView.builder(
          itemCount: incidencias.length,
          itemBuilder: (context, index) {
            final incidencia = incidencias[index];
            final color = incidencia.estado == 'Pendiente' ? Colors.red.shade600 : Colors.orange.shade600;

            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color,
                  child: const Icon(Icons.warning, color: Colors.white),
                ),
                // 🚀 CORRECCIÓN CLAVE: Usar nombreResidente en lugar de idResidente
                title: Text('Alerta de Residente: ${incidencia.nombreResidente}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),

                subtitle: Text(
                    'Detalles: ${incidencia.detalles ?? 'No proporcionados'}\n'
                        'Estado: ${incidencia.estado}\n'
                        'Hora: ${incidencia.timestamp.toDate().toLocal().toString().substring(11, 19)}'
                ),

                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IncidenciaDetalleScreen(incidencia: incidencia),
                    ),
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

  Widget n2(){
    return const Center(child: Text("hol3"),);
  }

  Widget n3(){
    return const Center(child: Text("hola4"),);
  }
}