import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dam_pfinal/controlador/basededatos.dart';
import 'package:dam_pfinal/modelo/incidencias.dart';

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

  late Future<List<Incidencia>> _incidenciasFuture;
  Position? _posicionActual;

  @override
  void initState() {
    super.initState();
    _incidenciasFuture = _cargarDatosDelMapa();
  }

  Future<List<Incidencia>> _cargarDatosDelMapa() async {
    Position posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    _posicionActual = posicion;

    List<Incidencia> listaIncidencias = await DB.mostrarIncidenciasPendientes();

    _actualizarMapa(posicion, listaIncidencias);

    return listaIncidencias;
  }

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
      final marker = Marker(
        markerId: MarkerId(incidencia.id),
        position: LatLng(incidencia.ubicacion.latitude, incidencia.ubicacion.longitude),
        infoWindow: InfoWindow(
          title: 'Alerta: ${incidencia.estado}',
          // Muestra los detalles de la incidencia en el snippet
          snippet: incidencia.detalles ?? 'Residente: ${incidencia.idResidente} (Sin detalles)',
          onTap: () {

          },
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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

        return GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _posicionActual != null
              ? CameraPosition(
              target: LatLng(_posicionActual!.latitude, _posicionActual!.longitude),
              zoom: 15
          )
              : _posicionInicial,
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
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