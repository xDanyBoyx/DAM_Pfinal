import 'package:cloud_firestore/cloud_firestore.dart';

class Incidencia {
  final String id;
  final String detalles;
  final String estado;
  final String idResidente;
  final Timestamp timestamp;
  final GeoPoint ubicacion;

  Incidencia({
    required this.id,
    required this.detalles,
    required this.estado,
    required this.idResidente,
    required this.timestamp,
    required this.ubicacion,
  });

  // Constructor de fábrica para crear un objeto Incidencia desde un documento de Firestore
  factory Incidencia.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Incidencia(
      id: doc.id,
      detalles: data['detalles'] ?? 'Sin detalles',
      estado: data['estado'] ?? 'Desconocido',
      idResidente: data['id_residente'] ?? 'Anónimo',
      // Firebase guarda las fechas como Timestamp, lo manejamos directamente
      timestamp: data['timestamp'] ?? Timestamp.now(),
      // Firebase guarda las ubicaciones como GeoPoint
      ubicacion: data['ubicacion'] ?? const GeoPoint(0, 0),
    );
  }
}
