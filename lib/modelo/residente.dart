
class Residente {
  String id;
  String name;
  int edad;
  String calle;
  String colonia;
  String noInt;
  String email;
  String password; // Recuerda que no es seguro guardar la contraseña aquí, pero la incluimos porque la tienes en tu modelo
  bool active;

  Residente({
    this.id = "",
    required this.name,
    required this.edad,
    required this.calle,
    required this.colonia,
    required this.noInt,
    required this.email,
    required this.password,
    this.active = false,
  });

  // Constructor de fábrica para crear una instancia de Residente desde un documento de Firestore
  factory Residente.fromFirestore(Map<String, dynamic> data, String documentId) {
    // Primero, verificamos que el mapa 'domicilio' existe y no es nulo.
    // Si no existe, usamos un mapa vacío para evitar errores al leer sus claves.
    final domicilioData = data['domicilio'] as Map<String, dynamic>? ?? {};

    return Residente(
      id: documentId,
      name: data['name'] ?? 'Sin Nombre',
      edad: data['edad'] ?? 0,


      calle: domicilioData['calle'] ?? 'Sin Calle',
      colonia: domicilioData['colonia'] ?? 'Sin Colonia',
      noInt: domicilioData['noInt'] ?? 'S/N',

      email: data['email'] ?? 'Sin Correo',
      password: data['password'] ?? '', 
      active: data['active'] ?? false,
    );
  }

}