import 'package:cloud_firestore/cloud_firestore.dart';

class Incidencia {
  // ID del documento en Firestore
  final String id;

  // Datos de la alerta
  final String idResidente;
  // 🚨 NUEVO CAMPO: Nombre del residente para mostrar en la interfaz
  final String? nombreResidente;
  final GeoPoint ubicacion; // Crucial para el mapa (G-2) y geocercado (G-4)
  final Timestamp timestamp;

  // Estado y validación
  String estado; // 'Pendiente', 'En Curso', 'Resuelta'
  bool zonaValida; // Resultado del geocercado del servidor

  // Información adicional
  final String? motivoInvalidez;
  final String? detalles;
  final Timestamp? ultimaActualizacion;

  Incidencia({
    required this.id,
    required this.idResidente,
    this.nombreResidente, // 🚨 Agregado al constructor 🚨
    required this.ubicacion,
    required this.timestamp,
    this.estado = 'Pendiente',
    this.zonaValida = false,
    this.motivoInvalidez,
    this.detalles,
    this.ultimaActualizacion,
  });

  // Constructor para crear la Incidencia a partir de datos de Firestore
  factory Incidencia.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Incidencia(
      id: doc.id,
      idResidente: data['id_residente'] ?? '',
      // NOTA: Este campo se llenará con la búsqueda en el controlador DB,
      // no directamente desde el documento de incidencia original.
      nombreResidente: null,
      ubicacion: data['ubicacion'] as GeoPoint,
      timestamp: data['timestamp'] as Timestamp,
      estado: data['estado'] ?? 'Pendiente',
      zonaValida: data['zona_valida'] ?? false,
      motivoInvalidez: data['motivo_invalidez'] as String?,
      detalles: data['detalles'] as String?,
      ultimaActualizacion: data['ultima_actualizacion'] as Timestamp?,
    );
  }

  // Método para convertir el objeto a un mapa (usado para crear)
  Map<String, dynamic> toMap() {
    return {
      'id_residente': idResidente,
      // No incluimos nombreResidente, ya que no se guarda en la DB de incidencias.
      'ubicacion': ubicacion,
      'timestamp': timestamp,
      'estado': estado,
      'zona_valida': zonaValida,
      'motivo_invalidez': motivoInvalidez,
      'detalles': detalles,
      'ultima_actualizacion': ultimaActualizacion,
    };
  }
}