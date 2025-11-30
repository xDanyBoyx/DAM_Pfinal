import 'package:flutter/material.dart';
import 'package:dam_pfinal/modelo/incidencias.dart';
import 'package:dam_pfinal/controlador/basededatos.dart';

class IncidenciaDetalleScreen extends StatelessWidget {
  final Incidencia incidencia;

  const IncidenciaDetalleScreen({super.key, required this.incidencia});

  Future<void> _actualizarEstado(BuildContext context, String nuevoEstado) async {
    try {
      // 1. Llamar a la función de la DB para actualizar el estado
      await DB.actualizarEstadoIncidencia(incidencia.id, nuevoEstado);

      // 2. Mostrar confirmación
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado actualizado a: $nuevoEstado'))
      );

      // 3. Regresar a la pantalla anterior (Lista de Incidencias)
      // Pasamos 'true' para indicarle a VentanaGuardia que debe recargar la lista.
      Navigator.pop(context, true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Incidencia', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo.shade300,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Información Básica ---
            Text('ID Residente:', style: Theme.of(context).textTheme.titleSmall),
            Text(incidencia.idResidente, style: Theme.of(context).textTheme.titleLarge),
            const Divider(),

            Text('Estado Actual:', style: Theme.of(context).textTheme.titleSmall),
            Text(incidencia.estado, style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: incidencia.estado == 'Pendiente' ? Colors.red.shade700 : Colors.orange.shade800,
            )),
            const Divider(),

            // --- Detalles ---
            Text('Detalles Adicionales:', style: Theme.of(context).textTheme.titleMedium),
            Text(incidencia.detalles ?? 'No proporcionados.'),

            const SizedBox(height: 20),
            Text('Hora de Alerta:', style: Theme.of(context).textTheme.titleMedium),
            Text(incidencia.timestamp.toDate().toLocal().toString()),

            const SizedBox(height: 40),

            // --- Botones de Gestión (G-3) ---

            // Botón 1: Tomar Incidencia (Pendiente -> En Curso)
            if (incidencia.estado == 'Pendiente')
              ElevatedButton.icon(
                onPressed: () => _actualizarEstado(context, 'En Curso'),
                icon: const Icon(Icons.directions_run),
                label: const Text('Tomar/Poner En Curso'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),

            const SizedBox(height: 15),

            // Botón 2: Resolver Incidencia (Disponible si no está resuelta)
            if (incidencia.estado != 'Resuelta')
              ElevatedButton.icon(
                onPressed: () => _actualizarEstado(context, 'Resuelta'),
                icon: const Icon(Icons.check_circle),
                label: Text(incidencia.estado == 'Pendiente' ? 'Resolver Directamente' : 'Finalizar/Resolver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
          ],
        ),
      ),
    );
  }
}