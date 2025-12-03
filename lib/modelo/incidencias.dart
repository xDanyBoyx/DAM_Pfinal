import 'package:cloud_firestore/cloud_firestore.dart';

class Incidencia {
  final String id;
  final String emailResidente;      // identificador por email, NO id
  final String? nombreResidente;    // se llena después con lookup por email

  final GeoPoint ubicacion;
  final Timestamp timestamp;

  String estado; // "Pendiente", "En Curso", "Resuelta"
  bool zonaValida;

  final String? motivoInvalidez;
  final String? detalles;
  final Timestamp? ultimaActualizacion;

  Incidencia({
    required this.id,
    required this.emailResidente,
    this.nombreResidente,
    required this.ubicacion,
    required this.timestamp,
    this.estado = 'Pendiente',
    this.zonaValida = false,
    this.motivoInvalidez,
    this.detalles,
    this.ultimaActualizacion,
  });

  /// --- copyWith CORREGIDO (usa emailResidente, no idResidente) ---
  Incidencia copyWith({
    String? id,
    String? emailResidente,
    String? nombreResidente,
    GeoPoint? ubicacion,
    Timestamp? timestamp,
    String? estado,
    bool? zonaValida,
    String? motivoInvalidez,
    String? detalles,
    Timestamp? ultimaActualizacion,
  }) {
    return Incidencia(
      id: id ?? this.id,
      emailResidente: emailResidente ?? this.emailResidente,
      nombreResidente: nombreResidente ?? this.nombreResidente,
      ubicacion: ubicacion ?? this.ubicacion,
      timestamp: timestamp ?? this.timestamp,
      estado: estado ?? this.estado,
      zonaValida: zonaValida ?? this.zonaValida,
      motivoInvalidez: motivoInvalidez ?? this.motivoInvalidez,
      detalles: detalles ?? this.detalles,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
    );
  }

  /// --- Factory from Firestore (seguro ante nulos/tipos) ---
  factory Incidencia.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Incidencia(
      id: doc.id,

      /// String seguro
      emailResidente: data['email_residente'] is String
          ? data['email_residente']
          : '',

      /// Este campo lo obtienes luego vía lookup por email
      nombreResidente: null,

      /// GeoPoint seguro
      ubicacion: data['ubicacion'] is GeoPoint
          ? data['ubicacion']
          : const GeoPoint(0, 0),

      /// Timestamp seguro
      timestamp: data['timestamp'] is Timestamp
          ? data['timestamp']
          : Timestamp.now(),

      /// Estado seguro (String)
      estado: data['estado'] is String
          ? data['estado']
          : 'Pendiente',

      /// Boolean seguro
      zonaValida: data['zona_valida'] is bool
          ? data['zona_valida']
          : false,

      /// Campos opcionales tipo String
      motivoInvalidez: data['motivo_invalidez'] is String
          ? data['motivo_invalidez']
          : null,

      detalles: data['detalles'] is String
          ? data['detalles']
          : null,

      /// Timestamp opcional seguro
      ultimaActualizacion: data['ultima_actualizacion'] is Timestamp
          ? data['ultima_actualizacion']
          : null,
    );
  }


  /// --- toMap para guardar en Firestore ---
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'email_residente': emailResidente,
      'ubicacion': ubicacion,
      'timestamp': timestamp,
      'estado': estado,
      'zona_valida': zonaValida,
    };
    if (motivoInvalidez != null) map['motivo_invalidez'] = motivoInvalidez;
    if (detalles != null) map['detalles'] = detalles;
    if (ultimaActualizacion != null) map['ultima_actualizacion'] = ultimaActualizacion;
    return map;
  }
}
