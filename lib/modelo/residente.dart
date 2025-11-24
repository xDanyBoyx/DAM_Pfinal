class Residente{
  String id = "";
  String name;
  int edad;
  String calle;
  String colonia;
  String noInt;
  String email;
  String password;
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
    this.active = false
});
}