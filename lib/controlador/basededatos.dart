import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dam_pfinal/modelo/guardia.dart';

var baseRemota = FirebaseFirestore.instance;

class DB {
  static Future<List<Guardia>> mostrarTodos() async {
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
      );
      temporal.add(guardia);
    });
    return temporal;
  }
}
