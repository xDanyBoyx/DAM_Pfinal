import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dam_pfinal/controlador/basededatos.dart';
import 'package:dam_pfinal/modelo/incidencias.dart';
import 'package:dam_pfinal/modelo/alerta_panico.dart'; // <--- Importante
import 'package:dam_pfinal/incidencia_detalle_screen.dart';

class GuardiaMapaScreen extends StatefulWidget {
  const GuardiaMapaScreen({super.key});

  @override
  State<GuardiaMapaScreen> createState() => _GuardiaMapaScreenState();
}

class _GuardiaMapaScreenState extends State<GuardiaMapaScreen> {
  // Posición inicial por defecto
  static const CameraPosition _posicionInicial = CameraPosition(
    target: LatLng(21.4925, -104.8443),
    zoom: 14,
  );

  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  bool _cargando = true;
  Position? _posicionActual;

  @override
  void initState() {
    super.initState();
    _inicializarMapa();
  }

  Future<void> _inicializarMapa() async {
    try {
      Position posicion = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (!mounted) return;

      _posicionActual = posicion;
      await _cargarDatosDelMapa();
    } catch (e) {
      print("Error obteniendo ubicación: $e");
      // Si falla GPS, intentamos cargar datos igual
      await _cargarDatosDelMapa();
    }
  }

  /// Carga Incidencias Y Alertas al mismo tiempo
  Future<void> _cargarDatosDelMapa() async {
    try {
      // Cargamos ambas listas en paralelo
      final resultados = await Future.wait([
        DB.mostrarIncidenciasPendientes(), // índice 0
        DB.mostrarAlertasPendientes()      // índice 1
      ]);

      if (!mounted) return;

      final incidencias = resultados[0] as List<Incidencia>;
      final alertas = resultados[1] as List<AlertaPanico>;

      _generarMarkers(incidencias, alertas);

      setState(() {
        _cargando = false;
      });

    } catch (e) {
      print("Error cargando datos del mapa: $e");
    }
  }

  void _generarMarkers(List<Incidencia> incidencias, List<AlertaPanico> alertas) {
    Set<Marker> nuevosMarkers = {};

    // 1. MARCADORES DE INCIDENCIAS (Rojos/Naranjas)
    for (var incidencia in incidencias) {
      if (incidencia.ubicacion.latitude == 0 && incidencia.ubicacion.longitude == 0) continue;

      final marker = Marker(
        markerId: MarkerId("inc_${incidencia.id}"), // Prefijo para evitar IDs duplicados
        position: LatLng(
          incidencia.ubicacion.latitude,
          incidencia.ubicacion.longitude,
        ),
        infoWindow: InfoWindow(
          title: 'Reporte: ${incidencia.nombreResidente ?? "Desconocido"}',
          snippet: incidencia.estado,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    IncidenciaDetalleScreen(incidencia: incidencia),
              ),
            );
            if (!mounted) return;
            if (result == true) {
              _cargarDatosDelMapa(); // Recargar si hubo cambios
            }
          },
        ),
        icon: incidencia.estado.toLowerCase() == 'pendiente'
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      );
      nuevosMarkers.add(marker);
    }

    // 2. MARCADORES DE ALERTAS DE PÁNICO (Violetas) 🟣
    for (var alerta in alertas) {
      if (alerta.ubicacion.latitude == 0 && alerta.ubicacion.longitude == 0) continue;

      final marker = Marker(
        markerId: MarkerId("sos_${alerta.id}"),
        position: LatLng(
          alerta.ubicacion.latitude,
          alerta.ubicacion.longitude,
        ),
        infoWindow: InfoWindow(
          title: '🚨 SOS: ${alerta.nombreResidente ?? "Desconocido"}',
          snippet: 'Hora: ${alerta.fecha.toDate().toLocal().toString().substring(11, 16)}',
          onTap: () {
            // Al tocar una alerta, mostramos diálogo rápido para atender
            _mostrarDialogoAtenderAlerta(alerta);
          },
        ),
        // Color Violeta para distinguir urgencia
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      );
      nuevosMarkers.add(marker);
    }

    if (!mounted) return;

    setState(() {
      _markers = nuevosMarkers;
    });
  }

  void _mostrarDialogoAtenderAlerta(AlertaPanico alerta) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("🚨 Alerta SOS"),
        content: Text("Ubicación de emergencia de ${alerta.nombreResidente}.\n\n¿Deseas marcarla como atendida?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cerrar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await DB.atenderAlerta(alerta.id);
              if (mounted) {
                _cargarDatosDelMapa(); // Recargar para quitar el pin
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Alerta atendida")),
                );
              }
            },
            child: const Text("MARCAR ATENDIDA"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando && _posicionActual == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final LatLng target = _posicionActual != null
        ? LatLng(_posicionActual!.latitude, _posicionActual!.longitude)
        : _posicionInicial.target;

    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: target,
        zoom: 15,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        if (_posicionActual != null && mounted) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(_posicionActual!.latitude, _posicionActual!.longitude),
                zoom: 15,
              ),
            ),
          );
        }
      },
    );
  }
}