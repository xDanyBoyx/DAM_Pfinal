import 'package:cloud_firestore/cloud_firestore.dart';

class AlertaPanico {
  final String id;
  final String activadaPor; // Email del residente
  final String residenteId; // ID del documento del residente
  final bool atendida;
  final Timestamp fecha;
  final GeoPoint ubicacion;

  // Campo extra para mostrar el nombre en la lista (no está en la BD, lo buscamos aparte)
  final String? nombreResidente;

  AlertaPanico({
    required this.id,
    required this.activadaPor,
    required this.residenteId,
    required this.atendida,
    required this.fecha,
    required this.ubicacion,
    this.nombreResidente,
  });

  // Fábrica segura para evitar errores de nulos
  factory AlertaPanico.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AlertaPanico(
      id: doc.id,
      activadaPor: (data['activadaPor'] as String?) ?? '',
      residenteId: (data['residenteId'] as String?) ?? '',
      atendida: (data['atendida'] as bool?) ?? false,
      fecha: (data['fecha'] as Timestamp?) ?? Timestamp.now(),
      ubicacion: (data['ubicacion'] as GeoPoint?) ?? const GeoPoint(0, 0),
    );
  }

  // Método para añadirle el nombre después de buscarlo
  AlertaPanico copyWith({String? nombreResidente}) {
    return AlertaPanico(
      id: id,
      activadaPor: activadaPor,
      residenteId: residenteId,
      atendida: atendida,
      fecha: fecha,
      ubicacion: ubicacion,
      nombreResidente: nombreResidente ?? this.nombreResidente,
    );
  }
}