// /functions/index.js

const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Inicializa el SDK de Admin para acceder a Firestore y FCM
admin.initializeApp();
const db = admin.firestore();

// ----------------------------------------------------
// (G-4) Define el Área Limítrofe: Centro y Radio
// ¡IMPORTANTE! Reemplaza esto con las coordenadas reales de tu fraccionamiento.
// ----------------------------------------------------
const CENTRO_FRACCIONAMIENTO = {lat: 20.659698, lon: -103.349609};
const RADIO_MAXIMO_KM = 0.5; // Límite de 500 metros

// ----------------------------------------------------
// Cloud Function: Se activa al crear una nueva incidencia
// ----------------------------------------------------
exports.procesarNuevaIncidencia = functions.firestore
    .document("incidencias/{incidenciaId}")
    .onCreate(async (snap, context) => {
      const datosAlerta = snap.data();
      const docId = context.params.incidenciaId;
      const ubicacion = datosAlerta.ubicacion;

      if (!ubicacion || !ubicacion.latitude || !ubicacion.longitude) {
        console.error(`Incidencia ${docId} sin ubicación válida. Cancelando.`);
        return db.collection("incidencias").doc(docId).update({zona_valida: false, motivo_invalidez: "Sin datos de GPS"});
      }

      // Lógica de Geocercado (G-4)
      const distanciaKM = calcularDistancia(
          {lat: ubicacion.latitude, lon: ubicacion.longitude},
          CENTRO_FRACCIONAMIENTO,
      );

      const esValida = distanciaKM <= RADIO_MAXIMO_KM;

      // Actualizar la incidencia con el resultado de la validación
      await db.collection("incidencias").doc(docId).update({zona_valida: esValida});

      if (!esValida) {
        // G-4: No genera notificación si es inválida
        console.log(`Alerta ${docId} fuera de zona (${distanciaKM.toFixed(3)} km). No se notifica.`);
        return null;
      }

      // Si es válida, Notificar al Guardia (G-1 y G-2)
      await enviarNotificacionGuardia(docId, ubicacion);
      return null;
    });


// ----------------------------------------------------
// Funciones Auxiliares
// ----------------------------------------------------

// Fórmula de Haversine para calcular distancia entre 2 puntos GeoPoint
function calcularDistancia(p1, p2) {
  const R = 6371; // Radio de la Tierra en kilómetros
  const dLat = (p2.lat - p1.lat) * (Math.PI / 180);
  const dLon = (p2.lon - p1.lon) * (Math.PI / 180);
  const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(p1.lat * (Math.PI / 180)) * Math.cos(p2.lat * (Math.PI / 180)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c; // Distancia en km
}


// Función de Notificación (G-1 y G-2)
async function enviarNotificacionGuardia(incidenciaId, ubicacion) {
  // Aquí es donde obtienes los tokens FCM de los guardias.
  // ASUME que tienes una colección para guardar los tokens de los dispositivos.
  const guardiaTokensSnapshot = await db.collection("fcmTokens")
      .where("rol", "==", "guardia")
      .get();

  const tokens = guardiaTokensSnapshot.docs.map((doc) => doc.data().token);

  if (tokens.length === 0) {
    console.warn("No se encontraron tokens de guardias para notificar.");
    return;
  }

  const payload = {
    notification: {
      title: "🚨 ALERTA DE INCIDENCIA INSTANTÁNEA",
      body: `Ubicación: ${ubicacion.latitude.toFixed(4)}, ${ubicacion.longitude.toFixed(4)}.`,
      sound: "default",
    },
    data: {
      incidenciaId: incidenciaId,
      lat: ubicacion.latitude.toString(),
      lon: ubicacion.longitude.toString(),
    },
  };

  await admin.messaging().sendToDevice(tokens, payload);
  console.log(`Notificación enviada a ${tokens.length} guardias.`);
}
