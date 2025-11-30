import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'modelo/guardia.dart';
import 'formulario_adm_guardia.dart';

class PantallaListaGuardias extends StatelessWidget {
  // Recibe el objeto del guardia que está usando la app para validar permisos.
  final Guardia guardiaActual;

  const PantallaListaGuardias({super.key, required this.guardiaActual});

  // Función de ayuda para la lógica de permisos. Determina si se muestran los botones de editar/borrar.
  bool puedeModificar(Guardia guardiaEnLista) {
    // Nadie puede modificarse a sí mismo.
    if (guardiaActual.id == guardiaEnLista.id) {
      return false;
    }

    // Reglas de negocio basadas en el rol.
    switch (guardiaActual.rango) {
      case 'admin':
      // El admin puede modificar a todos (excepto a sí mismo, ya validado arriba).
        return true;
      case 'sherif':
      // El sherif puede modificar a todos MENOS a los admin.
        return guardiaEnLista.rango != 'admin';
      case 'guardia':
      // El guardia no puede modificar a nadie.
        return false;
      default:
        return false;
    }
  }

  // --- Funciones para las Acciones ---

  void _navegarAFormularioCreacion(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Le pasamos el rango del usuario que está creando al formulario.
        builder: (context) => FormularioAdminGuardia(
          rangoDelUsuarioActual: guardiaActual.rango,
        ),
      ),
    );
  }

  // Navega al formulario para editar un guardia existente (funcionalidad futura).
  void _navegarAFormularioEdicion(BuildContext context, Guardia guardiaAEditar) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioAdminGuardia(
          guardiaAEditar: guardiaAEditar,
          rangoDelUsuarioActual: guardiaActual.rango, // <-- Y PÁSALE EL RANGO AQUÍ TAMBIÉN
        ),
      ),
    );
  }

  // Muestra un diálogo de confirmación antes de eliminar un guardia.
  void _mostrarDialogoBorrar(BuildContext context, Guardia guardiaABorrar) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que quieres eliminar a ${guardiaABorrar.name}? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(), // Cierra el diálogo
              child: const Text('Cancelar'),
            ),
            // 2. IMPLEMENTADO EL BOTÓN DE BORRADO REAL
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('guardia').doc(guardiaABorrar.id).delete();
                  // TODO: Considerar también borrar el usuario de Firebase Authentication si es necesario.
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${guardiaABorrar.name} ha sido eliminado.'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal de Guardia"),
        actions: [
          if (guardiaActual.rango== 'admin' || guardiaActual.rango == 'sherif')
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Agregar nuevo guardia',
              onPressed: () => _navegarAFormularioCreacion(context),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('guardia').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print(snapshot.error); // Imprime el error en consola para depuración
            return const Center(child: Text('Ocurrió un error al cargar los datos.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay guardias registrados.'));
          }

          final guardias = snapshot.data!.docs.map((doc) {
            return Guardia.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return ListView.builder(
            itemCount: guardias.length,
            itemBuilder: (context, index) {
              final guardiaItem = guardias[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    // 4. MEJORA VISUAL: Colores diferentes según el rol.
                    backgroundColor: guardiaItem.rango == 'admin' ? Colors.amber.shade700
                        : guardiaItem.rango == 'sherif' ? Colors.blue.shade700
                        : Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    child: Text(guardiaItem.rango.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(guardiaItem.name),
                  subtitle: Text('Rol: ${guardiaItem.rango}\nEmail: ${guardiaItem.email}'),
                  // Muestra los botones de acción solo si el usuario actual tiene permiso.
                  trailing: puedeModificar(guardiaItem)
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón de Editar
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        tooltip: 'Editar ${guardiaItem.name}',
                        onPressed: () => _navegarAFormularioEdicion(context, guardiaItem),
                      ),
                      // Botón de Borrar
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        tooltip: 'Eliminar ${guardiaItem.name}',
                        onPressed: () => _mostrarDialogoBorrar(context, guardiaItem),
                      ),
                    ],
                  )
                      : null, // Si no puede modificar, no muestra nada.
                ),
              );
            },
          );
        },
      ),
    );
  }
}
