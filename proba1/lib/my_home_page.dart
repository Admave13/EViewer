import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SerieDetailPage.dart';
import 'PlayerDetailPage.dart';
import 'package:proba1/CompetitionDetailPage.dart';
import 'package:proba1/TeamDetailPage.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class SerieData {
  final String equipo1;
  final String equipo2;
  final String competitionName;
  final String id;
  final int equipo1Count;
  final int equipo2Count;
  final bool jugado;
  final DateTime hora;
  final String? competitionId;
  final bool en_directo;
  final int jornada;

  SerieData({
    required this.equipo1,
    required this.equipo2,
    required this.competitionName,
    required this.id,
    required this.equipo1Count,
    required this.equipo2Count,
    required this.jugado,
    required this.hora,
    required this.competitionId,
    required this.en_directo,
    this.jornada=0,
  });
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late DateTime _today;
  late DateTime _yesterday;
  late DateTime _tomorrow;
  late int _jornada;
  late TabController _tabController;
  late List<SerieData> _seriesData = [];
  late List<SerieData> _seriesData_a = [];
  late List<SerieData> _seriesData_m = [];
  bool _loadingPartidos=false;

  @override
  void initState() {
    super.initState();
    _today = DateTime(2023, 6, 26);
    //_today = DateTime(2023, 4, 9);
    _yesterday = _today.subtract(Duration(days: 1));
    _tomorrow = _today.add(Duration(days: 1));
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(_handleTabSelection);
    _fetchSeriesData(_today);
    _fetchSeriesData_2(_yesterday);
    _fetchSeriesData_3(_tomorrow);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          break;
        case 1:
          break;
        case 2:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _loadingPartidos
          ? AppBar() // Mostrar una AppBar vacía mientras se carga
          : AppBar(
        title: Text("E-Viewer",
          style: TextStyle(color: Colors.white,fontFamily: 'Sequel100'), ),
        backgroundColor: Color(0xff6200ff),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          labelStyle: TextStyle(fontSize: 16.0,fontFamily: 'SequelSans'),
          unselectedLabelColor: Color(0xff2d0079),
          tabs: [
            Tab(text: "Ayer"),
            Tab(text: "Hoy"),
            Tab(text: "Mañana"),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color:Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(),
              );
              // Aquí puedes manejar la lógica de la búsqueda
              // Por ejemplo, abrir un cuadro de diálogo de búsqueda o navegar a una pantalla de búsqueda
            },
          ),
        ],
      ),
      body: _loadingPartidos
          ? Center(child: CircularProgressIndicator()) // Muestra un indicador de carga mientras se cargan los partidos
          : TabBarView(
        controller: _tabController,
        children: [
          _buildPage_2(_yesterday),
          _buildPage(_today),
          _buildPage_3(_tomorrow),
        ],
      ),
    );
  }


  Widget _buildPage(DateTime date) {
    return Center(
      child: _seriesData.isNotEmpty
          ? ListView.builder(
        itemCount: _seriesData.length,
        itemBuilder: (context, index) {
          final serieData = _seriesData[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 7.0), // Ajusta los padding según sea necesario
            title: ElevatedButton(
              onPressed: () {
                // Navegar a la pantalla de detalle de la serie con los datos de la serie seleccionada
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SerieDetailScreen(
                      id: serieData.id,
                      competition_id: serieData.competitionId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(

                textStyle: TextStyle(fontSize: 17.0, fontFamily: "Sequel100"),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                maximumSize: Size(100, 90), // Ajusta según sea necesario
                backgroundColor: serieData.en_directo ? Color(0xff6200ff) : Colors.white,
                foregroundColor: serieData.en_directo ? Color(0xff6200ff) : Colors.white,
                elevation: 0.1,
                side: BorderSide(width: 1.7, color: Color(0xff6200ff)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 0.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Texto de la competencia
                        Text(
                          "Jornada ${serieData.jornada.toString()}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "SequelSans",
                            fontSize: 10.0, // Tamaño de fuente más pequeño
                            color: serieData.en_directo ? Colors.white : Color(0xff6200ff),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Row para la parte superior del botón
                  // Agrupación de la imagen y el texto central
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Contenedor con un ancho fijo para el texto del lado izquierdo
                      SizedBox(
                        width: 65, // Ajusta según sea necesario
                        child: Text(
                          serieData.equipo1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: serieData.en_directo ? Colors.white : Color(0xff6200ff) ,

                          ),
                        ),
                      ),
                      // Imagen pequeña
                      Image.asset(
                          serieData.en_directo ? 'assets/${serieData.equipo1.toLowerCase()}2.png' : 'assets/${serieData.equipo1.toLowerCase()}.png',
                          width: 40,
                          height: 40
                      ),
                      // Espaciado entre la imagen y el texto central
                      // Contenedor con un ancho fijo para el texto central
                      SizedBox(
                        width: 120, // Ancho fijo para el texto central, ajusta según sea necesario
                        child: Text(
                          serieData.en_directo ? '${serieData.equipo1Count} - ${serieData.equipo2Count}' :
                          serieData.jugado ? '${serieData.equipo1Count} - ${serieData.equipo2Count}' : '${serieData.hora.hour}:${serieData.hora.minute.toString().padLeft(2, '0')}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: serieData.en_directo ? 30 : 24,
                            color: serieData.en_directo ? Colors.white : Color(0xff6200ff),
                          ),
                        ),
                      ),
                      // Espaciado entre el texto central y la segunda imagen
                      // Imagen pequeña
                      Image.asset(
                          serieData.en_directo ? 'assets/${serieData.equipo2.toLowerCase()}2.png' : 'assets/${serieData.equipo2.toLowerCase()}.png',
                          width: 40,
                          height: 40
                      ),
                      // Contenedor con un ancho fijo para el texto del lado derecho
                      SizedBox(
                        width: 65, // Ajusta según sea necesario
                        child: Text(
                          serieData.equipo2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: serieData.en_directo ? Colors.white : Color(0xff6200ff),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Nombre de la competencia en el centro en la parte inferior con un tamaño de fuente más pequeño
                  // Nombre de la competencia en el centro en la parte inferior con un tamaño de fuente más pequeño
                  Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Imagen pequeña
                        Image.asset(
                          serieData.en_directo ? 'assets/lec2.png' : 'assets/lec.png',
                          width: 15, // Ajusta el ancho según sea necesario
                          height: 15, // Ajusta el alto según sea necesario
                        ),
                        // Texto de la competencia
                        Text(
                          serieData.competitionName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "SequelSans",
                            fontSize: 8.0, // Tamaño de fuente más pequeño
                            color: serieData.en_directo ? Colors.white : Color(0xff6200ff),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          );
        },
      )
          : Text(
        "No se juegan partidos en este día.",
        style: TextStyle(fontSize: 18.0),
      ),
    );
  }
  Widget _buildPage_2(DateTime date) {
    return Center(
      child: _seriesData_a.isNotEmpty
          ? ListView.builder(
        itemCount: _seriesData_a.length,
        itemBuilder: (context, index) {
          final serieData = _seriesData_a[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 7.0),
            title: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SerieDetailScreen(
                      id: serieData.id,
                      competition_id: serieData.competitionId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                textStyle: TextStyle(fontSize: 17.0, fontFamily: "Sequel100"),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                maximumSize: Size(100, 90),
                backgroundColor: serieData.en_directo ? Color(0xff6200ff) : Colors.white,
                foregroundColor: serieData.en_directo ?   Color(0xff6200ff):Colors.white,
                elevation: 0.1,
                side: BorderSide(width: 1.7, color: Color(0xff6200ff)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 0.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Jornada ${serieData.jornada.toString()}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "SequelSans",
                            fontSize: 10.0,
                            color: serieData.en_directo ? Colors.white : Color(0xff6200ff),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 65,
                        child: Text(
                          serieData.equipo1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: serieData.en_directo ? Colors.white : Color(0xff6200ff),
                          ),
                        ),
                      ),
                      Image.asset(
                          serieData.en_directo ? 'assets/${serieData.equipo1.toLowerCase()}2.png' : 'assets/${serieData.equipo1.toLowerCase()}.png',
                          width: 40,
                          height: 40
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          serieData.jugado ? '${serieData.equipo1Count} - ${serieData.equipo2Count}' : '${serieData.hora.hour}:${serieData.hora.minute.toString().padLeft(2, '0')}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: serieData.jugado ? 30 : 24,
                            color: serieData.en_directo ? Colors.white : Color(0xff6200ff),
                          ),
                        ),
                      ),
                      Image.asset(
                          serieData.en_directo ? 'assets/${serieData.equipo2.toLowerCase()}2.png' : 'assets/${serieData.equipo2.toLowerCase()}.png',
                          width: 40,
                          height: 40
                      ),
                      SizedBox(
                        width: 65,
                        child: Text(
                          serieData.equipo2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: serieData.en_directo ? Colors.white : Color(0xff6200ff),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 0.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          serieData.en_directo ? 'assets/lec2.png' : 'assets/lec.png',
                          width: 15,
                          height: 15,
                        ),
                        Text(
                          serieData.competitionName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "SequelSans",
                            fontSize: 8.0,
                            color: serieData.en_directo ? Colors.white : Color(0xff6200ff),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      )
          : Text(
        "No se juegan partidos en este día.",
        style: TextStyle(fontSize: 18.0),
      ),
    );
  }

  Widget _buildPage_3(DateTime date) {
    return Center(
      child: _seriesData_m.isNotEmpty
          ? ListView.builder(
        itemCount: _seriesData_m.length,
        itemBuilder: (context, index) {
          final serieData = _seriesData_m[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
            title: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SerieDetailScreen(
                      id: serieData.id,
                      competition_id: serieData.competitionId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                textStyle: TextStyle(fontSize: 17.0, fontFamily: "Sequel100"),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                maximumSize: Size(100, 90),
                backgroundColor: Colors.white,
                foregroundColor: Colors.white ,
                elevation: 0.1,
                side: BorderSide(width: 1.7, color: Color(0xff6200ff)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 0.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Jornada ${serieData.jornada.toString()}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "SequelSans",
                            fontSize: 10.0,
                            color: Color(0xff6200ff),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 65,
                        child: Text(
                          serieData.equipo1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xff6200ff),
                          ),
                        ),
                      ),
                      Image.asset(
                          'assets/${serieData.equipo1.toLowerCase()}.png',
                          width: 40,
                          height: 40
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${serieData.hora.hour}:${serieData.hora.minute.toString().padLeft(2, '0')}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            color: serieData.en_directo ? Colors.white : Color(0xff6200ff),
                          ),
                        ),
                      ),
                      Image.asset(
                          'assets/${serieData.equipo2.toLowerCase()}.png',
                          width: 40,
                          height: 40
                      ),
                      SizedBox(
                        width: 65,
                        child: Text(
                          serieData.equipo2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: serieData.en_directo ? Colors.white : Color(0xff6200ff),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          serieData.en_directo ? 'assets/lec2.png' : 'assets/lec.png',
                          width: 15,
                          height: 15,
                        ),
                        Text(
                          serieData.competitionName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "SequelSans",
                            fontSize: 8.0,
                            color: serieData.en_directo ? Colors.white : Color(0xff6200ff),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      )
          : Text(
        "No se juegan partidos en este día.",
        style: TextStyle(fontSize: 18.0,fontFamily: "SequelSans",color: Color(0xff6200ff)),
      ),
    );
  }



  Future<void> _fetchSeriesData(DateTime date) async {
    var filterDate = date;
    var nextDay = filterDate.add(Duration(days: 1));
    var seriesQuery = FirebaseFirestore.instance
        .collectionGroup('series')
        .where('hora', isGreaterThanOrEqualTo: filterDate)
        .where('hora', isLessThan: nextDay)
        .orderBy('hora')
        .get();

    var seriesSnapshot = await seriesQuery;

    var seriesData = await Future.wait(seriesSnapshot.docs.map((doc) async {
      var equipo1 = doc.data()["equipo1"];
      var equipo2 = doc.data()["equipo2"];
      var jugado = doc.data()["jugado"];
      var id = doc.id;
      var hora = (doc.data()["hora"] as Timestamp).toDate();
      var competitionDoc = await doc.reference.parent.parent?.get();
      var competitionName = competitionDoc?.data()?['nombre']; // Obtener el campo "nombre" de la competición
      var competitionId = competitionDoc?.id;
      print(id);
      print(doc.data()["en_directo"] ?? false);
      if (jugado == true) {
        // Realizar consulta adicional si el partido está jugado
        var partidosRef = FirebaseFirestore.instance
            .collection('competition')
            .doc(competitionId)
            .collection('series')
            .doc(doc.id)
            .collection('partido')
            .get();

        var partidoSnapshot = await partidosRef;
        var equipo1Count = 0;
        var equipo2Count = 0;

        // Contar los partidos ganados por cada equipo
        partidoSnapshot.docs.forEach((partidoDoc) {
          var partidoData = partidoDoc.data();
          var ganador = partidoData["ganador"];
          if (ganador == equipo1) {
            equipo1Count++;
          } else if (ganador == equipo2) {
            equipo2Count++;
          }
        });

        return SerieData(
          equipo1: equipo1,
          equipo2: equipo2,
          competitionName: competitionName,
          equipo1Count: equipo1Count,
          equipo2Count: equipo2Count,
            jornada:int.parse(id.split("_")[1][1]),
          hora: hora,
          jugado: true,
          id: id,
            competitionId:competitionId,
            en_directo:doc.data()["en_directo"] ?? false
        );
      } else {
        return SerieData(
          equipo1: equipo1,
          equipo2: equipo2,
          equipo1Count: 0,
          equipo2Count: 0,
          competitionName: competitionName,
          jornada:int.parse(id.split("_")[1][1]),
          hora: hora,
          jugado: false,
            id: id,
            competitionId:competitionId,
            en_directo:doc.data()["en_directo"] ?? false
        );
      }
    }));

    setState(() {
      _seriesData = seriesData;
    });
    FlutterNativeSplash.remove();
  }

  Future<void> _fetchSeriesData_2(DateTime date) async {
    var filterDate = date;
    var nextDay = filterDate.add(Duration(days: 1));
    var seriesQuery = FirebaseFirestore.instance
        .collectionGroup('series')
        .where('hora', isGreaterThanOrEqualTo: filterDate)
        .where('hora', isLessThan: nextDay)
        .orderBy('hora')
        .get();

    var seriesSnapshot = await seriesQuery;

    var seriesData = await Future.wait(seriesSnapshot.docs.map((doc) async {
      var equipo1 = doc.data()["equipo1"];
      var equipo2 = doc.data()["equipo2"];
      var jugado = doc.data()["jugado"];
      var id = doc.id;
      var hora = (doc.data()["hora"] as Timestamp).toDate();
      var competitionDoc = await doc.reference.parent.parent?.get();
      var competitionName = competitionDoc?.data()?['nombre']; // Obtener el campo "nombre" de la competición
      var competitionId = competitionDoc?.id;
      print(id);
      print(doc.data()["en_directo"] ?? false);
      if (jugado == true) {
        // Realizar consulta adicional si el partido está jugado
        var partidosRef = FirebaseFirestore.instance
            .collection('competition')
            .doc(competitionId)
            .collection('series')
            .doc(doc.id)
            .collection('partido')
            .get();

        var partidoSnapshot = await partidosRef;
        var equipo1Count = 0;
        var equipo2Count = 0;

        // Contar los partidos ganados por cada equipo
        partidoSnapshot.docs.forEach((partidoDoc) {
          var partidoData = partidoDoc.data();
          var ganador = partidoData["ganador"];
          if (ganador == equipo1) {
            equipo1Count++;
          } else if (ganador == equipo2) {
            equipo2Count++;
          }
        });

        return SerieData(
            equipo1: equipo1,
            equipo2: equipo2,
            competitionName: competitionName,
            equipo1Count: equipo1Count,
            equipo2Count: equipo2Count,
            hora: hora,
            jugado: true,
            id: id,
            jornada:int.parse(id.split("_")[1][1]),
            competitionId:competitionId,
            en_directo:doc.data()["en_directo"] ?? false
        );
      } else {
        return SerieData(
            equipo1: equipo1,
            equipo2: equipo2,
            equipo1Count: 0,
            equipo2Count: 0,
            competitionName: competitionName,
            hora: hora,
            jornada:int.parse(id.split("_")[1][1]),
            jugado: false,
            id: id,
            competitionId:competitionId,
            en_directo:doc.data()["en_directo"] ?? false
        );
      }
    }));

    setState(() {
      _seriesData_a = seriesData;
    });
  }

  Future<void> _fetchSeriesData_3(DateTime date) async {
    var filterDate = date;
    var nextDay = filterDate.add(Duration(days: 1));
    var seriesQuery = FirebaseFirestore.instance
        .collectionGroup('series')
        .where('hora', isGreaterThanOrEqualTo: filterDate)
        .where('hora', isLessThan: nextDay)
        .orderBy('hora')
        .get();

    var seriesSnapshot = await seriesQuery;

    var seriesData = await Future.wait(seriesSnapshot.docs.map((doc) async {
      var equipo1 = doc.data()["equipo1"];
      var equipo2 = doc.data()["equipo2"];
      var jugado = doc.data()["jugado"];
      var id = doc.id;
      var hora = (doc.data()["hora"] as Timestamp).toDate();
      var competitionDoc = await doc.reference.parent.parent?.get();
      var competitionName = competitionDoc?.data()?['nombre']; // Obtener el campo "nombre" de la competición
      var competitionId = competitionDoc?.id;
      print(id);
      print(doc.data()["en_directo"] ?? false);
      if (jugado == true) {
        // Realizar consulta adicional si el partido está jugado
        var partidosRef = FirebaseFirestore.instance
            .collection('competition')
            .doc(competitionId)
            .collection('series')
            .doc(doc.id)
            .collection('partido')
            .get();

        var partidoSnapshot = await partidosRef;
        var equipo1Count = 0;
        var equipo2Count = 0;

        // Contar los partidos ganados por cada equipo
        partidoSnapshot.docs.forEach((partidoDoc) {
          var partidoData = partidoDoc.data();
          var ganador = partidoData["ganador"];
          if (ganador == equipo1) {
            equipo1Count++;
          } else if (ganador == equipo2) {
            equipo2Count++;
          }
        });

        return SerieData(
            equipo1: equipo1,
            equipo2: equipo2,
            competitionName: competitionName,
            equipo1Count: equipo1Count,
            equipo2Count: equipo2Count,
            hora: hora,
            jornada:int.parse(id.split("_")[1][1]),
            jugado: true,
            id: id,
            competitionId:competitionId,
            en_directo:doc.data()["en_directo"] ?? false
        );
      } else {
        return SerieData(
            equipo1: equipo1,
            equipo2: equipo2,
            equipo1Count: 0,
            equipo2Count: 0,
            jornada:int.parse(id.split("_")[1][1]),
            competitionName: competitionName,
            hora: hora,
            jugado: false,
            id: id,
            competitionId:competitionId,
            en_directo:doc.data()["en_directo"] ?? false
        );
      }
    }));

    setState(() {
      _seriesData_a = seriesData;
    });
  }
}


class CustomSearchDelegate extends SearchDelegate<String> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> nombresCompeticion = [];
  List<String> equipos = [];
  List<String> jugadores = [];
  List<String> nombresid = [];
  List<String> jugadoresid = [];
  List<String> equiposid = [];

  CustomSearchDelegate() {
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Obtener datos de la colección 'competition'
      QuerySnapshot competitionSnapshot = await _firestore.collection('competition').get();
      nombresCompeticion = competitionSnapshot.docs.map((doc) => doc['nombre'] as String).toList();
      nombresid = competitionSnapshot.docs.map((doc) => doc.id as String).toList();

      // Obtener datos de la colección 'players_info'
      QuerySnapshot playersSnapshot = await _firestore.collection('players_info').get();
      jugadores = playersSnapshot.docs.map((doc) => doc['ign'] as String).toList();
      jugadoresid = playersSnapshot.docs.map((doc) => doc.id as String).toList();

      // Obtener datos de la colección 'teams_info'
      QuerySnapshot teamsSnapshot = await _firestore.collection('teams_info').get();
      equipos = teamsSnapshot.docs.map((doc) => doc['nombre'] as String).toList();
      equiposid = teamsSnapshot.docs.map((doc) => doc.id as String).toList();
      print(equipos);
      print(equiposid);

    } catch (e) {
      print('Error al obtener datos: $e');
    }
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, ''); // Devolver una cadena vacía en lugar de null
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Aquí puedes mostrar los resultados basados en la query
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<String> suggestions = [];

    suggestions.addAll(nombresCompeticion.where((nombre) => nombre.toLowerCase().contains(query.toLowerCase())));
    suggestions.addAll(equipos.where((equipo) => equipo.toLowerCase().contains(query.toLowerCase())));
    suggestions.addAll(jugadores.where((jugador) => jugador.toLowerCase().contains(query.toLowerCase())));

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          title: Text(suggestion),
          onTap: () {
            if (nombresCompeticion.contains(suggestion))  { // Si se encuentra el elemento en nombresCompeticion
              final int indexInNombresCompeticion = nombresCompeticion.indexOf(suggestion);
              final nombreId = nombresid[indexInNombresCompeticion];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompetitionDetailPage(id: nombreId),
                ),
              );
            } else if (equipos.contains(suggestion)) {
              final int indexInNombresCompeticion = equipos.indexOf(suggestion);
              final nombreId = equiposid[indexInNombresCompeticion];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeamDetailPage(tricode: nombreId),
                ),
              );
              // Resto del código para los equipos
            } else if (jugadores.contains(suggestion)) {
              final int indexInNombresCompeticion = jugadores.indexOf(suggestion);
              final nombreId = jugadoresid[indexInNombresCompeticion];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerDetailPage(ign: nombreId),
                ),
              );
              // Resto del código para los jugadores
            }
          },
        );
      },
    );
  }
}

