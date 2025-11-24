import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dam_pfinal/modelo/guardia.dart';
import 'package:dam_pfinal/modelo/residente.dart';

var baseRemota = FirebaseFirestore.instance;

class DB {
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
        active: mapa['active']
      );
      temporal.add(guardia);
    });
    return temporal;
  }

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
}
