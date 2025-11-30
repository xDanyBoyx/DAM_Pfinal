import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';
import 'controlador/basededatos.dart';

class PantallaValidar extends StatefulWidget {
  const PantallaValidar({super.key});

  @override
  State<PantallaValidar> createState() => _PantallaValidarState();
}

class _PantallaValidarState extends State<PantallaValidar> {
  // Función que se ejecuta al presionar "Validar"
  void _validarUsuario(DocumentReference userRef) async {
    try {
      // Actualiza el campo 'active' a true
      await userRef.update({'active': true});

      // Muestra una confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Usuario validado con éxito.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.red,
              content: Text('Error al validar usuario: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Stream de guardias inactivos
    final Stream<QuerySnapshot> guardiasInactivosStream = baseRemota
        .collection('guardia')
        .where('active', isEqualTo: false)
        .snapshots();

    // Stream de residentes inactivos
    final Stream<QuerySnapshot> residentesInactivosStream = baseRemota
        .collection('residente')
        .where('active', isEqualTo: false)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios Pendientes'),
        backgroundColor: Colors.indigo.shade300,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<QuerySnapshot>>(
        stream: StreamZip([guardiasInactivosStream, residentesInactivosStream]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar usuarios'));
          }
          if (!snapshot.hasData ||
              snapshot.data!.every((qs) => qs.docs.isEmpty)) {
            return const Center(
                child: Text('No hay usuarios pendientes de validación.'));
          }

          // Combinamos los documentos de ambas colecciones
          final guardias = snapshot.data![0].docs;
          final residentes = snapshot.data![1].docs;
          final todosLosUsuarios = [...guardias, ...residentes];

          return ListView.builder(
            itemCount: todosLosUsuarios.length,
            itemBuilder: (context, index) {
              var usuario = todosLosUsuarios[index];
              // Determina el rol basado en la colección de origen
              String rol =
              usuario.reference.parent.id == 'guardia' ? 'Guardia' : 'Residente';
              String nombre = usuario['name'] ?? 'Sin Nombre';
              String email = usuario['email'] ?? 'Sin Correo';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Icon(rol == 'Guardia' ? Icons.security : Icons.person),
                  title: Text(nombre),
                  subtitle: Text('$rol - $email'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                    child: const Text('Validar'),
                    onPressed: () {
                      _validarUsuario(usuario.reference);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
