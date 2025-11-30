import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dam_pfinal/modelo/guardia.dart';
import 'package:dam_pfinal/modelo/residente.dart';
import 'package:dam_pfinal/modelo/incidencias.dart';
import 'package:dam_pfinal/modelo/aviso.dart'; // Mantener el nuevo modelo del Remoto

// Inicialización global de la instancia de Firestore
var baseRemota = FirebaseFirestore.instance;

class DB {

  // --- Funciones de Lectura (Read) ---

  // 1. Mostrar lista de Guardias
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
          active: mapa['active'],
      );
      temporal.add(guardia);
    });
    return temporal;
  }

  // 2. Mostrar lista de Residentes
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

  // --- Funciones de Incidencias (CRUD) ---

  // 3. C: Crear Incidencia (Usada por la app del Residente)
  static Future<void> crearIncidencia(Map<String, dynamic> datosAlerta) async {
    datosAlerta['estado'] = 'Pendiente';
    datosAlerta['timestamp'] = FieldValue.serverTimestamp();
    datosAlerta['zona_valida'] = false; // El servidor (G-4) validará esto.

    try {
      await baseRemota.collection("incidencias").add(datosAlerta);
      print("Incidencia creada con éxito. Esperando validación del servidor.");
    } catch (e) {
      print("Error al crear incidencia: $e");
    }
  }

  // 4. R: Mostrar Incidencias Pendientes (G-2) - CON BUSQUEDA DE NOMBRE (Versión Local)
  static Future<List<Incidencia>> mostrarIncidenciasPendientes() async {
    // 1. Consulta Inicial de Incidencias
    var query = await baseRemota.collection("incidencias")
        .where('estado', isNotEqualTo: 'Resuelta')
    // 🚨 CORRECCIÓN CLAVE: Se comenta la línea de validación de zona
    //     para que las incidencias se muestren aunque G-4 no esté implementado.
    // .where('zona_valida', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .get();

    if (query.docs.isEmpty) return [];

    // 2. Mapeo Asíncrono para adjuntar el nombre
    final List<Future<Incidencia>> futureIncidencias = query.docs.map((doc) async {
      final data = doc.data() as Map<String, dynamic>;
      final idResidente = data['id_residente'] as String;
      String nombreResidente = 'Desconocido';

      // 🚨 BÚSQUEDA EN LA COLECCIÓN 'RESIDENTE' 🚨
      try {
        final residenteDoc = await baseRemota.collection('residente').doc(idResidente).get();
        if (residenteDoc.exists) {
          // Asume que el campo del nombre es 'name'
          nombreResidente = residenteDoc.get('name') ?? 'ID: $idResidente';
        }
      } catch (e) {
        print("Error al buscar nombre del residente ($idResidente): $e");
      }

      // 3. Crear el objeto Incidencia con el nombre adjunto
      var incidencia = Incidencia.fromFirestore(doc);

      return Incidencia(
        id: incidencia.id,
        idResidente: incidencia.idResidente,
        nombreResidente: nombreResidente, // <-- Adjuntamos el nombre
        ubicacion: incidencia.ubicacion,
        timestamp: incidencia.timestamp,
        estado: incidencia.estado,
        zonaValida: incidencia.zonaValida,
        motivoInvalidez: incidencia.motivoInvalidez,
        detalles: incidencia.detalles,
        ultimaActualizacion: incidencia.ultimaActualizacion,
      );
    }).toList();

    // 4. Esperar a que TODAS las búsquedas de nombres terminen
    return Future.wait(futureIncidencias);
  }

  // 5. U: Actualizar Estado (Usada por la app del Guardia G-3)
  static Future<void> actualizarEstadoIncidencia(String idIncidencia, String nuevoEstado) async {
    try {
      await baseRemota.collection("incidencias").doc(idIncidencia).update({
        'estado': nuevoEstado,
        'ultima_actualizacion': FieldValue.serverTimestamp()
      });
      print("Incidencia $idIncidencia actualizada a estado: $nuevoEstado");
    } catch (e) {
      print("Error al actualizar estado: $e");
    }
  }

  // G-1: Backend para reportar una incidencia (Versión Remota)
  static Future<String> reportarIncidencia(Incidencia incidencia) async {
    try {
      await baseRemota.collection("incidencias").add(incidencia.toMap());
      return "ok";
    } catch (e) {
      print("Error al reportar la incidencia: $e");
      return "Error: $e";
    }
  }

  // G-6: Función para crear un nuevo aviso general (Versión Remota)
  static Future<String> crearAviso(Aviso aviso) async {
    try {
      // --- R-5: Implementación de la Lógica de Notificación ---
      print("LOG: [R-5] Se simula el envío de una notificación Push a todos los Residentes.");

      await baseRemota.collection("avisos").add(aviso.toMap());
      return "ok";
    } catch (e) {
      print("Error al crear aviso: $e");
      return "Error: $e";
    }
  }

  // R-4: Función para obtener y mostrar la lista de avisos (Lectura) (Versión Remota)
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

  // G-7: Función para actualizar un aviso existente (Versión Remota)
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

  // G-7: Función para eliminar un aviso (Versión Remota)
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