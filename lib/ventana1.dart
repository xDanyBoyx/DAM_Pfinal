import 'package:flutter/material.dart';
import 'package:dam_pfinal/controlador//basededatos.dart'; // Tu clase DB
import 'package:dam_pfinal/modelo/incidencias.dart'; // Modelo Incidencia (asumiendo que es incidencias.dart)
import 'package:dam_pfinal/mapa_screen_guardia.dart'; // Pantalla del Mapa (G-2)


class VentanaGuardia extends StatefulWidget {
  const VentanaGuardia({super.key});

  @override
  State<VentanaGuardia> createState() => _VentanaGuardiaState();
}

class _VentanaGuardiaState extends State<VentanaGuardia> {
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
              Tab(text: "Mapa", icon: Icon(Icons.map)), // Pestaña Mapa
              Tab(text: "Incidencias", icon: Icon(Icons.access_time_outlined)), // Pestaña Lista
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
            const GuardiaMapaScreen(), // G-2: Pantalla del Mapa
            listaIncidencias(),                     //  Lista de Incidencias Pendientes
            n2(),
            n3(),
          ],
        ),
        drawer: const Drawer(
          // ... contenido del Drawer si es necesario
        ),
      ),
    );
  }

  // Se elimina la función dataUsuarios() ya que ahora usamos GuardiaMapaScreen
  /* Widget dataUsuarios(){ return Center(child: Text("hola"),); } */

  // ----------------------------------------------------
  // N1: Lista de Incidencias Pendientes (G-2 Fuente de datos)
  // ----------------------------------------------------
  Widget listaIncidencias(){
    return FutureBuilder(
      // Manteniendo la llamada directa al Future, tal como estaba en tu código original
      future: DB.mostrarIncidenciasPendientes(),
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
                title: Text('Alerta de Residente: ${incidencia.idResidente}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),

                // 🚨 CAMBIO SOLICITADO: Se agrega la línea de detalles 🚨
                subtitle: Text(
                    'Detalles: ${incidencia.detalles ?? 'No proporcionados'}\n' // Línea de detalles
                        'Estado: ${incidencia.estado}\n'
                        'Hora: ${incidencia.timestamp.toDate().toLocal().toString().substring(11, 19)}'
                ),

                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Mantenemos la lógica original de onTap (solo el SnackBar)
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Incidencia ID: ${incidencia.id}. Tarea pendiente: cambiar estado (G-3)'))
                  );
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