import 'package:flutter/material.dart';

class VentanaResidente extends StatefulWidget {
  const VentanaResidente({super.key});

  @override
  State<VentanaResidente> createState() => _VentanaResidenteState();
}

class _VentanaResidenteState extends State<VentanaResidente> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("HOLA"),
      ),
    );
  }
}
