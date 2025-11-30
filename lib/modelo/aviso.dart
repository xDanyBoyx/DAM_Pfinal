import 'package:cloud_firestore/cloud_firestore.dart';

class Aviso {
  String id = "";
  String titulo;
  String contenido;
  String creadoPor; // Email o nombre del Guardia que lo crea
  DateTime fecha;

  Aviso({
    this.id = "",
    required this.titulo,
    required this.contenido,
    required this.creadoPor,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'contenido': contenido,
      'creadoPor': creadoPor,
      'fecha': fecha,
    };
  }

  factory Aviso.fromMap(String id, Map<String, dynamic> map) {
    Timestamp timestamp = map['fecha'] ?? Timestamp.now();

    return Aviso(
      id: id,
      titulo: map['titulo'] ?? '',
      contenido: map['contenido'] ?? '',
      creadoPor: map['creadoPor'] ?? 'Desconocido',
      fecha: timestamp.toDate(),
    );
  }
}