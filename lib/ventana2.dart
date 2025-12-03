import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dam_pfinal/main.dart';
import 'package:dam_pfinal/authentication/authentication.dart';
import 'package:dam_pfinal/controlador/basededatos.dart';
import 'package:dam_pfinal/modelo/aviso.dart';
import 'package:dam_pfinal/modelo/residente.dart';
import 'package:dam_pfinal/modelo/incidencias.dart'; // <--- Importar Incidencia
import 'package:dam_pfinal/residente_nuevo_reporte.dart'; // <--- Importar nueva pantalla
import 'package:dam_pfinal/notification/notificaciones.dart';
import 'package:intl/intl.dart'; // <--- Importar para formato de fecha

// El nombre de la clase se mantiene como VentanaResidente y ahora requiere el UID
class VentanaResidente extends StatefulWidget {
  final String uid;

  const VentanaResidente({super.key, required this.uid});

  @override
  State<VentanaResidente> createState() => _VentanaResidenteState();
}

class _VentanaResidenteState extends State<VentanaResidente> {
  late Future<Residente?> _residenteFuture;
  int _selectedIndex = 0; // Para el BottomNavigationBar

  // Lista de widgets para el BottomNavigationBar
  late final List<Widget> _widgetOptions = <Widget>[
    _pantallaAvisos(),
    _pantallaMisReportes(), // Nuevo: Historial de reportes del residente
    _pantallaPerfil(),
  ];

  @override
  void initState() {
    super.initState();

    // Cargar datos del residente
    _residenteFuture = obtenerDatosDeResidente(widget.uid);

    // Inicializar notificaciones locales
    Notificaciones.init();

    // Registrar listener solo cuando el widget esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Notificaciones.escucharAvisos();
      }
    });
  }

  // --- Funciones de navegación y datos ---

  Future<Residente?> obtenerDatosDeResidente(String uid) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('residente').doc(uid).get();
      if (doc.exists) {
        // Asumiendo que el modelo Residente tiene un factory constructor fromFirestore
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

  // R-3: NUEVA PANTALLA: Historial de reportes creados por el Residente
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

  // Tarjeta de reporte para el historial del residente
  Widget _reporteCard(Incidencia incidencia) {
    final fechaFormateada = DateFormat('dd MMM, hh:mm a').format(incidencia.timestamp.toDate());

    // Mapeo de estados
    final String estadoTexto;
    Color estadoColor;
    IconData estadoIcono;

    // Los reportes manuales son 'Pendiente' (Sin atender) o 'Resuelta' (Atendido)
    if (incidencia.estado == 'Resuelta') {
      estadoTexto = 'Atendido';
      estadoColor = Colors.green.shade700;
      estadoIcono = Icons.check_circle;
    } else {
      estadoTexto = 'No atendido';
      estadoColor = Colors.red.shade700;
      estadoIcono = Icons.watch_later;
    }

    // Asumimos que el título está al inicio de los detalles y lo separamos
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
          // Implementar navegación a detalle si es necesario
          print('Reporte seleccionado: ${incidencia.id}');
        },
      ),
    );
  }

  // R-4: Pantalla para mostrar la lista de Avisos (FutureBuilder para la BD)
  Widget _pantallaAvisos() {
    return FutureBuilder<List<Aviso>>(
      future: DB.mostrarAvisos(),
      builder: (context, snapshot) {
        // ... (Tu código existente para mostrar avisos) ...
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

  // R-5: Placeholder para la pantalla de Perfil
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

  // --- Widget Principal (Build) ---

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

      floatingActionButton: _selectedIndex == 1 // Muestra el botón solo si la pestaña de reportes está activa
          ? FloatingActionButton(
        onPressed: _navegarANuevoReporte,
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_alert),
        tooltip: 'Generar Nuevo Reporte Manual',
      )
          : null, // Oculta el botón en las otras pestañas

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign),
            label: 'Avisos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history), // Ícono para historial/reportes
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