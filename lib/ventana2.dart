import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dam_pfinal/main.dart';
import 'package:dam_pfinal/authentication/authentication.dart';
import 'package:dam_pfinal/modelo/residente.dart';
import 'package:dam_pfinal/notification/notificaciones.dart';
import 'package:dam_pfinal/controlador/basededatos.dart';
import 'package:dam_pfinal/modelo/aviso.dart';
import 'package:shake/shake.dart';
import 'package:geolocator/geolocator.dart';

// =========================================================================
//  CLASE/MODELO PARA MANEJAR LOS DATOS DEL HISTORIAL DE ALERTAS
// =========================================================================
class AlertaDePanico {
  final String id;
  final String activadaPor;
  final DateTime fecha;
  final bool atendida;
  final GeoPoint? ubicacion;

  AlertaDePanico({
    required this.id,
    required this.activadaPor,
    required this.fecha,
    required this.atendida,
    this.ubicacion,
  });
}

class VentanaResidente extends StatefulWidget {
  final String uid;

  const VentanaResidente({super.key, required this.uid});

  @override
  State<VentanaResidente> createState() => _VentanaResidenteState();
}

class _VentanaResidenteState extends State<VentanaResidente> {
  late Future<Residente?> _residenteFuture;
  late ShakeDetector _shakeDetector;

  @override
  void initState() {
    super.initState();

    _residenteFuture = obtenerDatosDeResidente(widget.uid);
    Notificaciones.init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Notificaciones.escucharAvisos();
      }
    });

    // Lógica del Shake Detector (Botón de pánico)
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (ShakeEvent event) {
        Notificaciones.mostrar(
          "Procesando Alerta...",
          "Obteniendo ubicación y enviando datos.",
        );
        guardarAlertaDePanico();
      },
    );
  }

  @override
  void dispose() {
    _shakeDetector.stopListening();
    super.dispose();
  }

  // =========================================================================
  //  FUNCIONES PARA EL BOTÓN DE PÁNICO CON UBICACIÓN
  // =========================================================================

  Future<Position?> _obtenerUbicacionActual() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Por favor, activa el servicio de ubicación (GPS).')));
      }
      return null;
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('El permiso de ubicación fue denegado.')));
        }
        return null;
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('La app necesita permisos de ubicación. Actívalos en la configuración.')));
      }
      return null;
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> guardarAlertaDePanico() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: No hay usuario logueado para enviar alerta.");
      return;
    }

    final Position? ubicacion = await _obtenerUbicacionActual();

    if (ubicacion == null) {
      print("Error: No se pudo obtener la ubicación. La alerta no fue enviada.");
      Notificaciones.mostrar(
        "Fallo al Enviar Alerta",
        "No se pudo obtener tu ubicación. Revisa los permisos y el GPS.",
      );
      return;
    }

    print("Ubicación obtenida: Lat ${ubicacion.latitude}, Lon ${ubicacion.longitude}");

    final String usuarioEmail = user.email ?? "Email no disponible";
    final DateTime ahora = DateTime.now();

    try {
      await FirebaseFirestore.instance.collection('alertas_panico').add({
        'activadaPor': usuarioEmail,
        'fecha': Timestamp.fromDate(ahora),
        'atendida': false,
        'residenteId': user.uid,
        'ubicacion': GeoPoint(ubicacion.latitude, ubicacion.longitude),
      });

      print("¡Éxito! Alerta de pánico con ubicación guardada en Firebase.");

      Notificaciones.mostrar(
        "¡Alerta Enviada!",
        "Tu alerta y ubicación han sido enviadas correctamente.",
      );

    } catch (e) {
      print("Error al guardar en Firebase: $e");
      Notificaciones.mostrar(
        "Error de Conexión",
        "No se pudo guardar la alerta en la base de datos.",
      );
    }
  }


  // =========================================================================
  //  FUNCIONES PARA EL PERFIL Y CIERRE DE SESIÓN
  // =========================================================================

  Future<Residente?> obtenerDatosDeResidente(String uid) async {
    try {
      DocumentSnapshot doc =
      await FirebaseFirestore.instance.collection('residente').doc(uid).get();
      if (doc.exists) {
        return Residente.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print("Error al obtener datos del residente: $e");
    }
    return null;
  }

  void _mostrarDialogoDeCierreSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                await Auth().cerrarSesion();
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MyApp()),
                      (Route<dynamic> route) => false,
                );
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  //  WIDGETS PARA LAS TARJETAS (CARD) DE AVISOS Y ALERTAS
  // =========================================================================

  Widget _avisoCard(Aviso aviso) {
    final String fechaFormato =
        '${aviso.fecha.day.toString().padLeft(2, '0')}/${aviso.fecha.month.toString().padLeft(2, '0')}/${aviso.fecha.year} '
        '${aviso.fecha.hour.toString().padLeft(2, '0')}:${aviso.fecha.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 15.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              aviso.titulo,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              aviso.contenido,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 15),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Publicado por: ${aviso.creadoPor.split('@').first}',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
                Text(
                  fechaFormato,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertaCard(AlertaDePanico alerta) {
    final String fechaFormato =
        '${alerta.fecha.day.toString().padLeft(2, '0')}/${alerta.fecha.month.toString().padLeft(2, '0')}/${alerta.fecha.year} '
        '${alerta.fecha.hour.toString().padLeft(2, '0')}:${alerta.fecha.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 15.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      surfaceTintColor: alerta.atendida ? Colors.green.shade100 : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Alerta de Pánico',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Icon(
                  alerta.atendida ? Icons.check_circle : Icons.warning_amber,
                  color: alerta.atendida ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  fechaFormato,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (alerta.ubicacion != null)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${alerta.ubicacion!.latitude.toStringAsFixed(4)}, ${alerta.ubicacion!.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 15),
            const Divider(),
            Center(
              child: Text(
                alerta.atendida ? 'ATENDIDA' : 'PENDIENTE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: alerta.atendida ? Colors.green.shade700 : Colors.orange.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // =========================================================================
  //  WIDGETS PARA LAS PESTAÑAS (AVISOS Y HISTORIAL)
  // =========================================================================

  Widget _pantallaAvisos() {
    return FutureBuilder<List<Aviso>>(
      future: DB.mostrarAvisos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar avisos: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay avisos generales publicados.'));
        }
        final avisos = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(10.0),
          itemCount: avisos.length,
          itemBuilder: (context, index) {
            return _avisoCard(avisos[index]);
          },
        );
      },
    );
  }

  Widget _pantallaHistorial() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("Inicia sesión para ver tu historial."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('alertas_panico')
          .where('residenteId', isEqualTo: currentUser.uid)
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar el historial: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No has generado ninguna alerta de pánico.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        final alertas = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(10.0),
          itemCount: alertas.length,
          itemBuilder: (context, index) {
            final alertaData = alertas[index].data() as Map<String, dynamic>;
            final AlertaDePanico alerta = AlertaDePanico(
              id: alertas[index].id,
              activadaPor: alertaData['activadaPor'] ?? 'N/A',
              fecha: (alertaData['fecha'] as Timestamp).toDate(),
              atendida: alertaData['atendida'] ?? false,
              ubicacion: alertaData['ubicacion'] as GeoPoint?,
            );
            return _alertaCard(alerta);
          },
        );
      },
    );
  }

  // =========================================================================
  //  MÉTODO BUILD (LA ESTRUCTURA DE LA PANTALLA)
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("MI FRACCIONAMIENTO", style: TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: Colors.indigo.shade300,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Cerrar sesión',
              onPressed: () => _mostrarDialogoDeCierreSesion(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "AVISOS", icon: Icon(Icons.campaign)),
              Tab(text: "HISTORIAL", icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _pantallaAvisos(),
            _pantallaHistorial(),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              FutureBuilder<Residente?>(
                future: _residenteFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return DrawerHeader(
                      decoration: BoxDecoration(color: Colors.indigo.shade300),
                      child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return DrawerHeader(
                      decoration: BoxDecoration(color: Colors.indigo.shade300),
                      child: const Center(child: Text('Error al cargar perfil', style: TextStyle(color: Colors.white))),
                    );
                  }
                  var residente = snapshot.data!;
                  return DrawerHeader(
                    decoration: BoxDecoration(color: Colors.indigo.shade300),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, size: 50, color: Colors.indigo),
                        ),
                        const SizedBox(height: 10),
                        Text(residente.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(residente.email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar Sesión'),
                onTap: () => _mostrarDialogoDeCierreSesion(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

