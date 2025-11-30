import 'package:cloud_firestore/cloud_firestore.dart';

class Incidencia {
  String id = "";
  double latitud;
  double longitud;
  String emailResidente;
  String estado; // "Pendiente", "En curso", "Resuelta"
  DateTime fechaHora;
  String tipo; // "Shake"

  Incidencia({
    this.id = "",
    required this.latitud,
    required this.longitud,
    required this.emailResidente,
    this.estado = "Pendiente",
    required this.fechaHora,
    this.tipo = "Alerta por Gesto (Shake)",
  });

  Map<String, dynamic> toMap() {
    return {
      'latitud': latitud,
      'longitud': longitud,
      'emailResidente': emailResidente,
      'estado': estado,
      'fechaHora': fechaHora,
      'tipo': tipo,
    };
  }

  factory Incidencia.fromMap(String id, Map<String, dynamic> map) {
    Timestamp timestamp = map['fechaHora'] ?? Timestamp.now();

    return Incidencia(
      id: id,
      latitud: map['latitud']?.toDouble() ?? 0.0,
      longitud: map['longitud']?.toDouble() ?? 0.0,
      emailResidente: map['emailResidente'] ?? '',
      estado: map['estado'] ?? 'Desconocido',
      fechaHora: timestamp.toDate(),
      tipo: map['tipo'] ?? 'Desconocido',
    );
  }
}