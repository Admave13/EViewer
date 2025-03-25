import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SerieDetailPage.dart';

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
    required this.en_directo
  });
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late DateTime _today;
  late DateTime _yesterday;
  late DateTime _tomorrow;
  late TabController _tabController;
  late List<SerieData> _seriesData = [];
  late List<SerieData> _seriesData_a = [];
  late List<SerieData> _seriesData_m = [];

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
      appBar: AppBar(
        title: Text("E-Viewer"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Ayer"),
            Tab(text: "Hoy"),
            Tab(text: "Mañana"),
          ],
        ),
      ),
      body: TabBarView(
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
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: ElevatedButton(
              onPressed: () {
                // Navegar a la pantalla de detalle de la serie con los datos de la serie seleccionada
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SerieDetailScreen(
                      //serieData:serieData
                        id: serieData.id,
                        competition_id: serieData.competitionId
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 40.0),
                textStyle: TextStyle(fontSize: 20.0),
                // Verificar si está en directo para aplicar el borde rojo
                side: serieData.en_directo ? BorderSide(color: Colors.red) : BorderSide.none,
              ),
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Text(
                  serieData.en_directo
                      ? "${serieData.equipo1} ${serieData.equipo1Count} - ${serieData.equipo2Count} ${serieData.equipo2}\n${serieData.competitionName}"
                      : serieData.jugado
                      ? "${serieData.equipo1} ${serieData.equipo1Count} - ${serieData.equipo2Count} ${serieData.equipo2}\n${serieData.competitionName}"
                      : "${serieData.equipo1} ${serieData.hora.hour}:${serieData.hora.minute.toString().padLeft(2, '0')} ${serieData.equipo2} \n${serieData.competitionName}",
                  textAlign: TextAlign.center,
                ),
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
  Widget _buildPage_2(DateTime date) {
    return Center(
      child: _seriesData_a.isNotEmpty
          ? ListView.builder(
        itemCount: _seriesData_a.length,
        itemBuilder: (context, index) {
          final serieData = _seriesData_a[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: ElevatedButton(
              onPressed: () {
                // Navegar a la pantalla de detalle de la serie con los datos de la serie seleccionada
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SerieDetailScreen(
                      //serieData:serieData
                        id: serieData.id,
                        competition_id: serieData.competitionId
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 40.0),
                textStyle: TextStyle(fontSize: 20.0),
                // Verificar si está en directo para aplicar el borde rojo
                side: serieData.en_directo ? BorderSide(color: Colors.red) : BorderSide.none,
              ),
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Text(
                  serieData.en_directo
                      ? "${serieData.equipo1} ${serieData.equipo1Count} - ${serieData.equipo2Count} ${serieData.equipo2}\n${serieData.competitionName}"
                      : serieData.jugado
                      ? "${serieData.equipo1} ${serieData.equipo1Count} - ${serieData.equipo2Count} ${serieData.equipo2}\n${serieData.competitionName}"
                      : "${serieData.equipo1} ${serieData.hora.hour}:${serieData.hora.minute.toString().padLeft(2, '0')} ${serieData.equipo2} \n${serieData.competitionName}",
                  textAlign: TextAlign.center,
                ),
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
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: ElevatedButton(
              onPressed: () {
                // Navegar a la pantalla de detalle de la serie con los datos de la serie seleccionada
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SerieDetailScreen(
                      //serieData:serieData
                        id: serieData.id,
                        competition_id: serieData.competitionId
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 40.0),
                textStyle: TextStyle(fontSize: 20.0),
                // Verificar si está en directo para aplicar el borde rojo
                side: BorderSide(
                  color: serieData.en_directo ? Colors.red : Colors.transparent,
                  width: 2.0, // Ancho del borde
                ),
              ),
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Text(
                  serieData.en_directo
                      ? "${serieData.equipo1} ${serieData.equipo1Count} - ${serieData.equipo2Count} ${serieData.equipo2}\n${serieData.competitionName}"
                      : serieData.jugado
                      ? "${serieData.equipo1} ${serieData.equipo1Count} - ${serieData.equipo2Count} ${serieData.equipo2}\n${serieData.competitionName}"
                      : "${serieData.equipo1} ${serieData.hora.hour}:${serieData.hora.minute.toString().padLeft(2, '0')} ${serieData.equipo2} \n${serieData.competitionName}",
                  textAlign: TextAlign.center,
                ),
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

