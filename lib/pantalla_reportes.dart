import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'modelo/incidencia.dart';

class PantallaReportes extends StatelessWidget {
  const PantallaReportes({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Center(
              child: Text(
                "Historial de Incidencias",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
          const Divider(indent: 16, endIndent: 16), // Un separador visual
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('incidencias')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Ocurrió un error al cargar los reportes.'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay reportes de incidencias.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                final incidencias = snapshot.data!.docs.map((doc) {
                  return Incidencia.fromFirestore(doc);
                }).toList();

                return ListView.builder(
                  itemCount: incidencias.length,
                  itemBuilder: (context, index) {
                    final incidencia = incidencias[index];
                    final fechaFormateada = DateFormat('dd/MM/yyyy, hh:mm a').format(incidencia.timestamp.toDate());

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      elevation: 3,
                      child: ListTile(
                        leading: const Icon(Icons.error, color: Colors.redAccent, size: 40),
                        title: Text(
                          incidencia.detalles,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Estado: ${incidencia.estado}\nReportado: $fechaFormateada',
                        ),
                        trailing: Center(
                          widthFactor: 0.5, // Opcional: Reduce el espacio que ocupa el Center
                          child: const Icon(Icons.arrow_forward_ios),
                        ),
                        isThreeLine: true,
                        onTap: () {
                          print('Viendo detalles de la incidencia: ${incidencia.id}');
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
