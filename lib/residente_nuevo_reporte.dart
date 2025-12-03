import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'controlador/basededatos.dart';
class NuevoReporteScreen extends StatefulWidget {
  const NuevoReporteScreen({super.key});

  @override
  State<NuevoReporteScreen> createState() => _NuevoReporteScreenState();
}

class _NuevoReporteScreenState extends State<NuevoReporteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _mensajeController = TextEditingController();
  bool _estaCargando = false;

  /// Función para obtener la posición actual del dispositivo.
  Future<Position> _determinarPosicionActual() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio de ubicación está activo
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Los servicios de ubicación están deshabilitados. Por favor, actívalos.';
    }

    // Verificar y solicitar permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Permiso de ubicación denegado por el usuario.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Los permisos de ubicación están denegados permanentemente. Debes cambiarlos en los ajustes del sistema.';
    }

    // Obtener la ubicación actual
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
    );
  }


  Future<void> _enviarReporte() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _estaCargando = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() => _estaCargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: usuario no autenticado.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      // 1. Obtener la ubicación
      final position = await _determinarPosicionActual();
      final ubicacion = GeoPoint(position.latitude, position.longitude);

      // 2. Enviar a Firestore
      final resultado = await DB.crearIncidenciaManual(
        user.uid,
        user.email!,
        _tituloController.text.trim(),
        _mensajeController.text.trim(),
        ubicacion,
      );

      if (!mounted) return;

      if (resultado == "ok") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte enviado con éxito. El guardia lo revisará.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Cerrar la pantalla de reporte
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultado), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _estaCargando = false);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo reporte'),
        backgroundColor: Colors.indigo.shade300,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                "Ingresa el asunto y los detalles de tu reporte.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Campo de Título
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Asunto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.short_text),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa un título.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Campo de Mensaje/Detalles
              TextFormField(
                controller: _mensajeController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Mensaje/Detalles de la incidencia',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa una descripción.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: _estaCargando ? null : _enviarReporte,
                icon: _estaCargando
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.send),
                label: Text(_estaCargando ? 'Obteniendo ubicación y enviando...' : 'Enviar reporte y ubicación'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tu ubicación actual se adjuntará automáticamente.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}