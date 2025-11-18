import 'package:firebase_auth/firebase_auth.dart';

class Auth {
  final FirebaseAuth microServicio = FirebaseAuth.instance;

  Future<String> inscribir(String u, String c) async {
    try {
      await microServicio.createUserWithEmailAndPassword(email: u, password: c);
    } on FirebaseAuthException catch (e) {
      return e.message!;
    }
    return "ok";
  }

  Future<String> autenticacion(String u, String c) async {
    try {
      await microServicio.signInWithEmailAndPassword(email: u, password: c);
    } on FirebaseAuthException catch (e) {
      return e.message!;
    }
    return "ok";
  }

  bool estaAutenticado(){
    if(microServicio.currentUser==null) return false;
    return true;
  }

  Future cerrarSesion(){
    return microServicio.signOut();
  }
}
