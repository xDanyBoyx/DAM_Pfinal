import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dam_pfinal/controlador/basededatos.dart';
import 'package:dam_pfinal/modelo/incidencias.dart';
// 🚨 NECESARIO: Importar la pantalla de detalle para la navegación 🚨
import 'package:dam_pfinal/incidencia_detalle_screen.dart';


class GuardiaMapaScreen extends StatefulWidget {
  const GuardiaMapaScreen({super.key});

  @override
  State<GuardiaMapaScreen> createState() => _GuardiaMapaScreenState();
}

class _GuardiaMapaScreenState extends State<GuardiaMapaScreen> {
  static const CameraPosition _posicionInicial = CameraPosition(
    target: LatLng(21.4925, -104.8443),
    zoom: 14,
  );

  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  // Future que carga las incidencias y se actualiza con setState
  late Future<List<Incidencia>> _incidenciasFuture;
  Position? _posicionActual;

  @override
  void initState() {
    super.initState();
    _incidenciasFuture = _cargarDatosDelMapa();
  }

  // Función que se encarga de obtener la posición y las incidencias
  Future<List<Incidencia>> _cargarDatosDelMapa() async {
    Position posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    _posicionActual = posicion;

    // Llama a la DB que ahora incluye la búsqueda del nombre del residente
    List<Incidencia> listaIncidencias = await DB.mostrarIncidenciasPendientes();

    // Actualiza los marcadores y la vista del mapa
    _actualizarMapa(posicion, listaIncidencias);

    return listaIncidencias;
  }

  // Función para crear los Markers y gestionar la navegación
  void _actualizarMapa(Position centro, List<Incidencia> incidencias) {
    Set<Marker> nuevosMarkers = {};

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(centro.latitude, centro.longitude),
            zoom: 15,
          ),
        ),
      );
    }

    for (var incidencia in incidencias) {
      // Si la ubicación es nula, se salta este elemento
      if (incidencia.ubicacion == null) continue;

      final marker = Marker(
        markerId: MarkerId(incidencia.id),
        // Usamos el operador ! para acceder a latitud/longitud, confiando en el 'continue' de arriba
        position: LatLng(incidencia.ubicacion!.latitude, incidencia.ubicacion!.longitude),
        infoWindow: InfoWindow(
          // 🚨 Muestra el nombre del residente 🚨
          title: 'Alerta de: ${incidencia.nombreResidente}',
          snippet: incidencia.detalles ?? 'Estado: ${incidencia.estado}',

          // 🚨 ACCIÓN CLAVE: Navegación y recarga 🚨
          onTap: () async {
            // Navega a la pantalla de gestión y espera que regrese un resultado
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IncidenciaDetalleScreen(incidencia: incidencia),
              ),
            );

            // Si el resultado es 'true' (el estado se cambió), recargar el mapa
            if (result == true) {
              setState(() {
                _incidenciasFuture = _cargarDatosDelMapa();
              });
            }
          },
        ),
        icon: incidencia.estado == 'Pendiente'
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed) // Rojo para Pendiente
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), // Naranja para En Curso
      );
      nuevosMarkers.add(marker);
    }

    setState(() {
      _markers = nuevosMarkers;
    });
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Incidencia>>(
      future: _incidenciasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text("Error al cargar mapa y datos: ${snapshot.error}", textAlign: TextAlign.center),
          );
        }

        // Si no hay datos (snapshot.data es null o vacío) pero el FutureBuilder ya terminó
        final LatLng initialTarget = _posicionActual != null
            ? LatLng(_posicionActual!.latitude, _posicionActual!.longitude)
            : _posicionInicial.target;

        final double initialZoom = _posicionActual != null ? 15 : _posicionInicial.zoom;


        return GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: initialTarget,
            zoom: initialZoom,
          ),
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            // Solo llamar a _actualizarMapa aquí si ya tenemos datos y posición
            if (snapshot.hasData && _posicionActual != null) {
              _actualizarMapa(_posicionActual!, snapshot.data!);
            }
          },
          myLocationEnabled: true,
          zoomControlsEnabled: true,
        );
      },
    );
  }
}