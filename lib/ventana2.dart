import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dam_pfinal/main.dart';
import 'package:dam_pfinal/authentication/authentication.dart';
import 'package:dam_pfinal/controlador/basededatos.dart';
import 'package:dam_pfinal/modelo/aviso.dart';
import 'package:dam_pfinal/modelo/residente.dart';
import 'package:dam_pfinal/modelo/incidencias.dart';
import 'package:dam_pfinal/residente_nuevo_reporte.dart';
import 'package:dam_pfinal/notification/notificaciones.dart';
import 'package:intl/intl.dart';
// --- IMPORTACIONES FALTANTES ---
import 'package:shake/shake.dart';
import 'package:geolocator/geolocator.dart';

class VentanaResidente extends StatefulWidget {
  final String uid;

  const VentanaResidente({super.key, required this.uid});

  @override
  State<VentanaResidente> createState() => _VentanaResidenteState();
}

class _VentanaResidenteState extends State<VentanaResidente> {
  late Future<Residente?> _residenteFuture;
  int _selectedIndex = 0;

  // --- VARIABLE PARA EL SENSOR ---
  late ShakeDetector _shakeDetector;

  late final List<Widget> _widgetOptions = <Widget>[
    _pantallaAvisos(),
    _pantallaMisReportes(),
    _pantallaPerfil(),
  ];

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

    // --- AQUÍ ACTIVAMOS EL SENSOR DE AGITACIÓN ---
    _shakeDetector = ShakeDetector.autoStart(
      shakeThresholdGravity: 2.7, // Ajuste de sensibilidad
      onPhoneShake: (ShakeEvent event) {
        // Al agitar, llamamos a la función de pánico
        print("¡SHAKE DETECTADO!");
        Notificaciones.mostrar(
          "Procesando Alerta...",
          "Obteniendo ubicación y enviando datos.",
        );
        guardarAlertaDePanico();
      },
    );
  }

  // --- IMPORTANTE: APAGAR EL SENSOR AL SALIR ---
  @override
  void dispose() {
    _shakeDetector.stopListening();
    super.dispose();
  }

  // =========================================================================
  //  LÓGICA DEL BOTÓN DE PÁNICO (Traída del código de tu compañero)
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
      print("Error: No se pudo obtener la ubicación.");
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
      // Guardamos en la colección 'alertas_panico'
      await FirebaseFirestore.instance.collection('alertas_panico').add({
        'activadaPor': usuarioEmail,
        'fecha': Timestamp.fromDate(ahora),
        'atendida': false,
        'residenteId': user.uid,
        'ubicacion': GeoPoint(ubicacion.latitude, ubicacion.longitude),
      });

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
  //  RESTO DE TU CÓDIGO (Navegación y UI)
  // =========================================================================

  Future<Residente?> obtenerDatosDeResidente(String uid) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('residente').doc(uid).get();
      if (doc.exists) {
        return Residente.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print("Error al obtener datos del residente: $e");
    }
    return null;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

  void _navegarANuevoReporte() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NuevoReporteScreen(),
      ),
    );
  }

  // --- Widgets de Pantallas ---

  Widget _pantallaMisReportes() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      return const Center(child: Text("Error: Usuario no logueado."));
    }

    return Scaffold(
      body: StreamBuilder<List<Incidencia>>(
        stream: DB.streamIncidenciasPorResidente(user.email!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar reportes: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No has generado reportes manuales.',
                    style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          final reportes = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: reportes.length,
            itemBuilder: (context, index) {
              return _reporteCard(reportes[index]);
            },
          );
        },
      ),

    );
  }

  Widget _reporteCard(Incidencia incidencia) {
    final fechaFormateada = DateFormat('dd MMM, hh:mm a').format(incidencia.timestamp.toDate());

    final String estadoTexto;
    Color estadoColor;
    IconData estadoIcono;

    if (incidencia.estado == 'Resuelta') {
      estadoTexto = 'Atendido';
      estadoColor = Colors.green.shade700;
      estadoIcono = Icons.check_circle;
    } else {
      estadoTexto = 'No atendido';
      estadoColor = Colors.red.shade700;
      estadoIcono = Icons.watch_later;
    }

    final detallesCompleto = incidencia.detalles ?? "Sin detalles";
    final lineas = detallesCompleto.split('\n');
    final titulo = lineas.isNotEmpty && lineas[0].startsWith('Título:')
        ? lineas[0].substring(7).trim()
        : 'Reporte Manual Sin Título';

    final mensajePreview = lineas.length > 3
        ? lineas.sublist(3).join('\n').trim()
        : detallesCompleto;


    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(estadoIcono, color: estadoColor, size: 30),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estado: $estadoTexto', style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              mensajePreview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Fecha: $fechaFormateada',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        isThreeLine: true,
        onTap: () {
          print('Reporte seleccionado: ${incidencia.id}');
        },
      ),
    );
  }

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
            final aviso = avisos[index];
            final fechaFormato = DateFormat('dd/MM/yyyy hh:mm a').format(aviso.fecha);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 4,
              child: ListTile(
                title: Text(aviso.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(aviso.contenido),
                trailing: Text(fechaFormato, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _pantallaPerfil() {
    return FutureBuilder<Residente?>(
      future: _residenteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Error al cargar datos de perfil.'));
        }

        final residente = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    Text(residente.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(residente.email, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                    const Divider(height: 30),
                    _buildInfoRow(Icons.calendar_today, 'Edad', '${residente.edad} años'),
                    _buildInfoRow(Icons.location_on, 'Calle', residente.calle),
                    _buildInfoRow(Icons.business, 'Colonia', residente.colonia),
                    _buildInfoRow(Icons.house, 'No. Interior', residente.noInt),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
              onTap: () => _mostrarDialogoDeCierreSesion(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo.shade300, size: 20),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "MI FRACCIONAMIENTO",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade300,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),

      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
        onPressed: _navegarANuevoReporte,
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_alert),
        tooltip: 'Generar Nuevo Reporte Manual',
      )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign),
            label: 'Avisos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Mis Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo.shade600,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}