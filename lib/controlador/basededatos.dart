import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dam_pfinal/modelo/guardia.dart';
import 'package:dam_pfinal/modelo/residente.dart';
import 'package:dam_pfinal/modelo/incidencias.dart';
import 'package:dam_pfinal/modelo/aviso.dart';
import 'package:dam_pfinal/modelo/alerta_panico.dart';

final baseRemota = FirebaseFirestore.instance;

class DB {
  // ====================================================================
  // GUARDIAS
  // ====================================================================

  static Future<List<Guardia>> mostrarGuardia() async {
    try {
      final query = await baseRemota.collection("guardia").get();

      return query.docs.map((doc) {
        final data = doc.data();

        return Guardia(
          id: doc.id,
          // 🛡️ CORREGIDO: Protección contra nulos
          name: (data['name'] as String?) ?? 'Sin Nombre',
          edad: data['edad'],
          rango: data['rango'],
          email: (data['email'] as String?) ?? '',
          password: (data['password'] as String?) ?? '',
          active: data['active'] ?? false,
        );
      }).toList();
    } catch (e) {
      print("Error al obtener guardias: $e");
      return [];
    }
  }

  // ====================================================================
  // RESIDENTES
  // ====================================================================

  static Future<List<Residente>> mostrarResidente() async {
    try {
      final query = await baseRemota.collection("residente").get();

      return query.docs.map((doc) {
        final data = doc.data();
        final domicilio = data["domicilio"] ?? {};

        return Residente(
          id: doc.id,
          // 🛡️ CORREGIDO: Protección contra nulos
          name: (data['name'] as String?) ?? 'Sin Nombre',
          edad: data['edad'],
          calle: (domicilio['calle'] as String?) ?? '',
          colonia: (domicilio['colonia'] as String?) ?? '',
          noInt: (domicilio['noInt'] as String?) ?? '',
          email: (data['email'] as String?) ?? '',
          password: (data['password'] as String?) ?? '',
          active: data['active'] ?? false,
        );
      }).toList();
    } catch (e) {
      print("Error al obtener residentes: $e");
      return [];
    }
  }

  // ====================================================================
  // INCIDENCIAS
  // ====================================================================

  /// Crear incidencia desde app Residente
  static Future<void> crearIncidencia(Map<String, dynamic> datos) async {
    try {
      datos['estado'] = 'Pendiente';
      datos['timestamp'] = FieldValue.serverTimestamp();
      datos['zona_valida'] = false;

      // Aquí ya NO usamos id_residente. Solo email_residente.
      await baseRemota.collection("incidencias").add(datos);
    } catch (e) {
      print("Error al crear incidencia: $e");
    }
  }

  /// Mostrar incidencias NO resueltas + nombre del residente (por EMAIL)
  static Future<List<Incidencia>> mostrarIncidenciasPendientes() async {
    try {
      final query = await baseRemota
          .collection("incidencias")
          .where('estado', isNotEqualTo: 'Resuelta')
          .orderBy('estado')
          .orderBy('timestamp', descending: true)
          .get();

      if (query.docs.isEmpty) return [];

      final lista = query.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        final emailResidente = data['email_residente'];

        // Buscar residente por email
        String nombreResidente = "Desconocido";

        try {
          if (emailResidente != null) {
            final r = await baseRemota
                .collection("residente")
                .where("email", isEqualTo: emailResidente)
                .limit(1)
                .get();

            if (r.docs.isNotEmpty) {
              final dataRes = r.docs.first.data();
              // 🛡️ CORREGIDO: Aquí estaba el error. Forzamos la protección.
              nombreResidente = (dataRes["name"] as String?) ?? "Desconocido";
            }
          }
        } catch (_) {}

        // Convertimos el documento en modelo
        final incidencia = Incidencia.fromFirestore(doc);

        // Y le agregamos el nombre usando copyWith()
        return incidencia.copyWith(nombreResidente: nombreResidente);
      }).toList();

      return Future.wait(lista);
    } catch (e) {
      print("Error al obtener incidencias: $e");
      return [];
    }
  }

  /// Actualizar estado de incidencia
  static Future<void> actualizarEstadoIncidencia(
      String idIncidencia, String nuevoEstado) async {
    try {
      await baseRemota.collection("incidencias").doc(idIncidencia).update({
        'estado': nuevoEstado,
        'ultima_actualizacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error al actualizar incidencia: $e");
    }
  }

  /// Crear incidencia (versión con modelo)
  static Future<String> reportarIncidencia(Incidencia incidencia) async {
    try {
      await baseRemota.collection("incidencias").add(incidencia.toMap());
      return "ok";
    } catch (e) {
      return "Error: $e";
    }
  }

  // ====================================================================
  // ALERTAS DE PÁNICO (STREAM) 🚨
  // ====================================================================

  /// Escuchar alertas en TIEMPO REAL
  static Stream<List<AlertaPanico>> streamAlertas() {
    return baseRemota
        .collection("alertas_panico")
        .where('atendida', isEqualTo: false) // Solo traemos las activas
        .orderBy('fecha', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {

      List<AlertaPanico> lista = [];

      for (var doc in snapshot.docs) {
        try {
          // 1. Convertir documento a objeto AlertaPanico
          final alerta = AlertaPanico.fromFirestore(doc);
          String nombre = "Desconocido";

          // 2. Buscar nombre del residente usando el email (activadaPor)
          if (alerta.activadaPor.isNotEmpty) {
            final query = await baseRemota
                .collection("residente")
                .where("email", isEqualTo: alerta.activadaPor)
                .limit(1)
                .get();

            if (query.docs.isNotEmpty) {
              nombre = (query.docs.first.data()['name'] as String?) ?? "Sin Nombre";
            }
          }

          // 3. Añadir a la lista con el nombre encontrado
          lista.add(alerta.copyWith(nombreResidente: nombre));
        } catch (e) {
          print("Error procesando alerta: $e");
        }
      }
      return lista;
    });
  }

  /// Marcar alerta como atendida (La desaparece de la lista del guardia)
  static Future<void> atenderAlerta(String id) async {
    try {
      await baseRemota.collection("alertas_panico").doc(id).update({
        'atendida': true,
      });
    } catch (e) {
      print("Error atendiendo alerta: $e");
    }
  }

  /// Obtener alertas pendientes una sola vez (para el Mapa)
  static Future<List<AlertaPanico>> mostrarAlertasPendientes() async {
    try {
      final query = await baseRemota
          .collection("alertas_panico")
          .where('atendida', isEqualTo: false)
          .orderBy('fecha', descending: true)
          .get();

      if (query.docs.isEmpty) return [];

      // Procesamos la lista para buscar los nombres de los residentes
      final lista = query.docs.map((doc) async {
        final alerta = AlertaPanico.fromFirestore(doc);
        String nombre = "Desconocido";

        if (alerta.activadaPor.isNotEmpty) {
          try {
            final q = await baseRemota
                .collection("residente")
                .where("email", isEqualTo: alerta.activadaPor)
                .limit(1)
                .get();
            if (q.docs.isNotEmpty) {
              nombre = (q.docs.first.data()['name'] as String?) ?? "Sin Nombre";
            }
          } catch (_) {}
        }
        return alerta.copyWith(nombreResidente: nombre);
      }).toList();

      return Future.wait(lista);
    } catch (e) {
      print("Error obteniendo alertas para mapa: $e");
      return [];
    }
  }

  // AVISOS


  static Future<String> crearAviso(Aviso aviso) async {
    try {
      await baseRemota.collection("avisos").add(aviso.toMap());
      return "ok";
    } catch (e) {
      return "Error: $e";
    }
  }



  static Future<List<Aviso>> mostrarAvisos() async {
    try {
      final query = await baseRemota
          .collection("avisos")
          .orderBy("fecha", descending: true)
          .get();

      return query.docs
          .map((doc) => Aviso.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print("Error al obtener avisos: $e");
      return [];
    }
  }

  static Future<String> actualizarAviso(Aviso aviso) async {
    try {
      await baseRemota.collection("avisos").doc(aviso.id).update(aviso.toMap());
      return "ok";
    } catch (e) {
      return "Error: $e";
    }
  }

  static Future<String> eliminarAviso(String id) async {
    try {
      await baseRemota.collection("avisos").doc(id).delete();
      return "ok";
    } catch (e) {
      return "Error: $e";
    }
  }

  /// Escuchar incidencias en TIEMPO REAL (Stream) con protección anti-fallos
  static Stream<List<Incidencia>> streamIncidenciasPendientes() {
    return baseRemota
        .collection("incidencias")
        .where('estado', isNotEqualTo: 'Resuelta') // Solo trae pendientes/en curso
        .orderBy('estado')
        .orderBy('timestamp', descending: true)
        .snapshots() // <--- Esto mantiene la conexión abierta
        .asyncMap((snapshot) async {

      List<Incidencia> listaIncidencias = [];

      for (var doc in snapshot.docs) {
        try {
          // 1. Convertir datos (Seguro)
          final incidencia = Incidencia.fromFirestore(doc);

          // 2. Buscar nombre del residente
          String nombreResidente = "Desconocido";
          if (incidencia.emailResidente.isNotEmpty) {
            final queryRes = await baseRemota
                .collection("residente")
                .where("email", isEqualTo: incidencia.emailResidente)
                .limit(1)
                .get();

            if (queryRes.docs.isNotEmpty) {
              // Protección contra nombres nulos
              nombreResidente = (queryRes.docs.first.data()['name'] as String?) ?? "Sin Nombre";
            }
          }

          // 3. Añadir a la lista
          listaIncidencias.add(incidencia.copyWith(nombreResidente: nombreResidente));
        } catch (e) {
          print("Error procesando una incidencia en stream: $e");
        }
      }
      return listaIncidencias;
    });
  }


}