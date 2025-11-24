import 'package:flutter/material.dart';

class VentanaGuardia extends StatefulWidget {
  const VentanaGuardia({super.key});

  @override
  State<VentanaGuardia> createState() => _VentanaGuardiaState();
}

class _VentanaGuardiaState extends State<VentanaGuardia> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text(
            "MI FRACCIONAMIENTO",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.indigo.shade300,
          bottom: TabBar(
            tabs: [
              Tab(text: "USUARIOS", icon: Icon(Icons.people)),
              Tab(text: "N1", icon: Icon(Icons.access_time_outlined)),
              Tab(text: "N2", icon: Icon(Icons.edit_note_outlined)),
              Tab(text: "N3", icon: Icon(Icons.apple)),
            ],
            labelStyle: TextStyle(color: Colors.red, fontSize: 16),
            unselectedLabelStyle: TextStyle(color: Colors.white, fontSize: 12),
            indicatorWeight: 5,
          ),
        ),
        body: TabBarView(
          children: [
            dataUsuarios(),
            n1(),
            n2(),
            n3(),
          ],
        ),
        drawer: Drawer(

        ),
      ),
    );
  }

  Widget dataUsuarios(){
    return Center(child: Text("hola"),);
  }

  Widget n1(){
    return Center(child: Text("hol2"),);
  }

  Widget n2(){
    return Center(child: Text("hol3"),);
  }

  Widget n3(){
    return Center(child: Text("hola4"),);
  }
}
