import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Notificaciones {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    await _localNotificationsPlugin.initialize(settings);
  }

  static Future<void> mostrar(String titulo, String cuerpo) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'canal_avisos',
      'Avisos',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    // ID único para cada notificación
    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      titulo,
      cuerpo,
      platformDetails,
    );
  }

  /// Escucha los avisos y notifica solo a residentes
  static void escucharAvisos() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final String uid = currentUser.uid;

    FirebaseFirestore.instance.collection('avisos').snapshots().listen((snapshot) async {
      for (var cambio in snapshot.docChanges) {
        if (cambio.type == DocumentChangeType.added) {
          final aviso = cambio.doc.data();
          if (aviso == null) continue;

          // Verifica que sea residente y que aún no haya visto la notificación
          List<dynamic> vistos = aviso['vistos'] ?? [];
          String creadoPor = aviso['creadoPor'] ?? "";

          // Solo residentes (no creadores) y no repetidas
          if (!vistos.contains(uid) && creadoPor != currentUser.email) {
            await mostrar(aviso['titulo'], aviso['contenido']);

            // Marca como visto para este residente
            FirebaseFirestore.instance.collection('avisos').doc(cambio.doc.id).update({
              'vistos': FieldValue.arrayUnion([uid])
            });
          }
        }
      }
    });
  }
}
