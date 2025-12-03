import 'package:flutter/material.dart';
import 'package:dam_pfinal/modelo/incidencias.dart';
import 'package:dam_pfinal/controlador/basededatos.dart';

class IncidenciaDetalleScreen extends StatefulWidget {
  final Incidencia incidencia;

  const IncidenciaDetalleScreen({super.key, required this.incidencia});

  @override
  State<IncidenciaDetalleScreen> createState() => _IncidenciaDetalleScreenState();
}

class _IncidenciaDetalleScreenState extends State<IncidenciaDetalleScreen> {
  // Variable para saber si estamos guardando cambios
  bool _estaCargando = false;

  Future<void> _actualizarEstado(String nuevoEstado) async {
    // 1. Activamos el modo "Cargando" para bloquear botones
    setState(() {
      _estaCargando = true;
    });

    try {
      // 2. Intentamos actualizar en la base de datos
      await DB.actualizarEstadoIncidencia(widget.incidencia.id, nuevoEstado);

      // 🛡️ PROTECCIÓN CRÍTICA:
      // Verificamos si la pantalla sigue abierta antes de usar el contexto
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a: $nuevoEstado'),
          backgroundColor: Colors.green,
        ),
      );

      // 3. Regresamos 'true' para que el Mapa o la Lista se actualicen
      Navigator.pop(context, true);

    } catch (e) {
      // Si falla, quitamos el cargando y mostramos error
      if (!mounted) return;

      setState(() {
        _estaCargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
        ),
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
      body: Stack(
        children: [
          // CONTENIDO PRINCIPAL
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Residente:', style: Theme.of(context).textTheme.titleSmall),
                Text(
                  widget.incidencia.nombreResidente ?? 'Desconocido',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 5),
                Text(
                  'Email: ${widget.incidencia.emailResidente}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Divider(),

                  // -------------------
                  // ESTADO ACTUAL
                  // -------------------
                  Text('Estado Actual:', style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    widget.incidencia.estado,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.incidencia.estado == 'Pendiente'
                          ? Colors.red.shade700
                          : widget.incidencia.estado == 'En Curso'
                          ? Colors.orange.shade800
                          : Colors.green.shade700,
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text('Acciones del Guardia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  const SizedBox(height: 10),

                  // --- ACCIONES DEL GUARDIA: Sin Atender / Atendido ---

                  // 1. Botón para marcar como 'Sin atender' (Pendiente)
                  if (widget.incidencia.estado != 'Pendiente') // Si no está ya pendiente
                    ElevatedButton.icon(
                      onPressed: _estaCargando ? null : () => _actualizarEstado('Pendiente'),
                      icon: const Icon(Icons.watch_later),
                      label: const Text('Marcar como Sin Atender'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),

                  const SizedBox(height: 15),

                  // 2. Botón para marcar como 'Atendido' (Resuelta)
                  if (widget.incidencia.estado != 'Resuelta') // Si no está ya resuelta
                    ElevatedButton.icon(
                      onPressed: _estaCargando ? null : () => _actualizarEstado('Resuelta'),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Marcar como Atendido'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  const SizedBox(height: 15),
              ],
            ),
          ),

          // INDICADOR DE CARGA (Overlay)
          // Si está cargando, mostramos un bloqueo con spinner
          if (_estaCargando)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}