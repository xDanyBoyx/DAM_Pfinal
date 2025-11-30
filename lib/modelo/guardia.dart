class Guardia {
  String id = "";
  String name;
  int edad;
  String rango;
  String email;
  String password;
  bool active;

  Guardia({
    this.id = "",
    required this.name,
    required this.edad,
    required this.rango,
    required this.email,
    required this.password,
    this.active = false,
  });

  // Recibe un mapa (los datos de Firestore) y crea un objeto Guardia.
  factory Guardia.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Guardia(
      id: documentId,
      name: data['name'] ?? 'Sin Nombre',
      email: data['email'] ?? 'Sin Correo',
      rango: data['rango'] ?? 'Sin Rango',
      edad: data['edad'] ?? 0,
      active: data['active'] ?? false,
      password: data['password'] ?? '',
    );
  }
}

