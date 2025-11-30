import 'package:flutter/material.dart';
import 'package:dam_pfinal/controlador/basededatos.dart';
import 'package:dam_pfinal/modelo/aviso.dart';

class VentanaResidente extends StatefulWidget {
  const VentanaResidente({super.key});

  @override
  State<VentanaResidente> createState() => _VentanaResidenteState();
}

class _VentanaResidenteState extends State<VentanaResidente> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 1. Avisos (Tu Tarea R-4), 2. Historial (Tarea de Diego R-3)
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
      future: DB.mostrarAvisos(), // Llama a la función de lectura que pusiste en basededatos.dart
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