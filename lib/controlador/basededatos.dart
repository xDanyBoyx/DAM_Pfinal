import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dam_pfinal/modelo/guardia.dart';
import 'package:dam_pfinal/modelo/residente.dart';
import 'package:dam_pfinal/modelo/incidencia.dart';
import 'package:dam_pfinal/modelo/aviso.dart';

var baseRemota = FirebaseFirestore.instance;

class DB {
  static Future<List<Guardia>> mostrarGuardia() async {
    List<Guardia> temporal = [];

    var query = await baseRemota.collection("guardia").get();
    query.docs.forEach((element) {
      Map<String, dynamic> mapa = element.data();

      var guardia = Guardia(
        id: element.id,
        name: mapa['name'],
        edad: mapa['edad'],
        rango: mapa['rango'],
        email: mapa['email'],
        password: mapa['password'],
        active: mapa['active']
      );
      temporal.add(guardia);
    });
    return temporal;
  }

  static Future<List<Residente>> mostrarResidente() async {
    List<Residente> temporal = [];

    var query = await baseRemota.collection("residente").get();
    query.docs.forEach((element) {
      Map<String, dynamic> mapa = element.data();
      Map<String, dynamic> domicilio = mapa["domicilio"];

      var residente = Residente(
        id: element.id,
        name: mapa['name'],
        edad: mapa['edad'],
        calle: domicilio['calle'],
        colonia: domicilio['colonia'],
        noInt: domicilio['noInt'],
        email: mapa['email'],
        password: mapa['password'],
        active: mapa['active']
      );
      temporal.add(residente);
    });
    return temporal;
  }

  // G-1: Backend para reportar una incidencia (Dependencia)
  static Future<String> reportarIncidencia(Incidencia incidencia) async {
    try {
      await baseRemota.collection("incidencias").add(incidencia.toMap());
      return "ok";
    } catch (e) {
      print("Error al reportar la incidencia: $e");
      return "Error: $e";
    }
  }

// G-6: Función para crear un nuevo aviso general
  static Future<String> crearAviso(Aviso aviso) async {
    try {
      // --- R-5: Implementación de la Lógica de Notificación ---
      // Aquí se usaría Firebase Cloud Messaging (FCM) para enviar
      // una notificación push a todos los dispositivos registrados
      // en el topic 'residentes' o a todos los tokens de residente.
      print("LOG: [R-5] Se simula el envío de una notificación Push a todos los Residentes.");
      // Se asumiría que la función real sería algo como:
      // await enviarNotificacionFCM(titulo: aviso.titulo, cuerpo: aviso.contenido);
      // --------------------------------------------------------

      await baseRemota.collection("avisos").add(aviso.toMap());
      return "ok";
    } catch (e) {
      print("Error al crear aviso: $e");
      return "Error: $e";
    }
  }

  // R-4: Función para obtener y mostrar la lista de avisos (Lectura)
  static Future<List<Aviso>> mostrarAvisos() async {
    List<Aviso> listaAvisos = [];

    var query = await baseRemota
        .collection("avisos")
        .orderBy("fecha", descending: true)
        .get();

    for (var doc in query.docs) {
      listaAvisos.add(Aviso.fromMap(doc.id, doc.data()));
    }

    return listaAvisos;
  }

  // G-7: Función para actualizar un aviso existente
  static Future<String> actualizarAviso(Aviso aviso) async {
    try {
      await baseRemota
          .collection("avisos")
          .doc(aviso.id)
          .update(aviso.toMap());
      return "ok";
    } catch (e) {
      return "Error al actualizar aviso: $e";
    }
  }

  // G-7: Función para eliminar un aviso
  static Future<String> eliminarAviso(String avisoId) async {
    try {
      await baseRemota
          .collection("avisos")
          .doc(avisoId)
          .delete();
      return "ok";
    } catch (e) {
      return "Error al eliminar aviso: $e";
    }
  }

}
