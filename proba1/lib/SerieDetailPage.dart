import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proba1/PartidoDetailPage.dart';
import 'PlayerDetailPage.dart';
import 'CompetitionDetailPage.dart';
import 'TeamDetailPage.dart';
import 'PartidoDetailPage.dart';



class SerieData {
  final String equipo1;
  final String equipo2;
  final String competitionName;
  final String competitionID;
  final bool jugado;
  final DateTime hora;
  late int equipo1Count;
  late int equipo2Count;
  late String id;
  late String ganador;
  late bool acabado1; //se pueden borrar??
  late bool acabado2;
  final String grupo;
  final bool en_directo;

  SerieData({
    required this.equipo1,
    required this.equipo2,
    required this.competitionName,
    required this.competitionID,
    required this.jugado,
    required this.hora,
    required this.id,
    required this.ganador,
    required this.equipo1Count,
    required this.equipo2Count,
    required this.en_directo,
    this.grupo = 'no', // Valor predeterminado 'no' si el grupo es nulo
  });
}

class PartidoData {
  final String id;
  final String ladoAzul;
  final String ladoRojo;
  final String ganador;
  final bool en_directo;

  PartidoData({
    required this.id,
    required this.ladoAzul,
    required this.ladoRojo,
    required this.ganador,
    required this.en_directo
  });
}

class Jugador {
  final String ign;
  final String posicion;
  final String foto;

  Jugador(this.ign, this.posicion, this.foto);
}

class SerieDetailScreen extends StatefulWidget {
  final String id;
  final String? competition_id;


  SerieDetailScreen({required this.id, required this.competition_id});

  @override
  _SerieDetailScreenState createState() => _SerieDetailScreenState();
}

class _SerieDetailScreenState extends State<SerieDetailScreen> {
  late SerieData _serieData = SerieData(
    equipo1: "Null",
    equipo2: "Null",
    competitionName: "Null",
    competitionID: "Null",
    jugado: false,
    hora: DateTime(0, 0, 0),
    id:"",
    ganador:"Null",
    equipo1Count:0,
    equipo2Count:0,
    en_directo: false

  );
  late List<PartidoData> _partidoIds = [];
  late bool _loadingSerie = true;
  late bool _loadingPartidos = true;
  late bool _loadingPartidos2 = true;
  List<SerieData> _partidosPrevios = [];
  int _ganado1=0;
  int _ganado2=0;
  String selectedGroup = 'A';
  late List<SerieData> grupoA=[]; // Lista para el grupo A
  late List<SerieData> grupoB=[]; // Lista para el grupo B
  late List<SerieData> listaAMostrar=grupoA;
  String selectedClasificacion="lr";


  @override
  void initState() {
    super.initState();
    _fetchSerieData();
    _fetchPartidoIds();
  }

  void _fetchSerieData() async {
    final seriesSnapshot = await FirebaseFirestore.instance
        .collection('competition')
        .doc(widget.competition_id)
        .collection('series')
        .doc(widget.id)
        .get();

    final serieData = seriesSnapshot.data() as Map<String, dynamic>;
    final jugado = serieData['jugado'];
    final hora = (serieData['hora'] as Timestamp).toDate();
    final competitionDoc = await seriesSnapshot.reference.parent.parent?.get();
    final competitionName = competitionDoc
        ?.data()?['nombre']; // Obtener el campo "nombre" de la competición
    final competitionID = competitionDoc!.id;
    setState(() {
      _serieData = SerieData(
        equipo1: serieData['equipo1'],
        equipo2: serieData['equipo2'],
        competitionName: competitionName,
        competitionID: competitionID,
        jugado: jugado,
        hora: hora,
        id:widget.id,
        ganador:serieData['ganador'],
        equipo1Count: int.parse(serieData['equipo1Count']),
        equipo2Count: int.parse(serieData['equipo2Count']),
          grupo:serieData["grupo"] ?? 'no',
          en_directo:serieData["en_directo"] ?? false
      );
    });
    //print(_serieData.grupo);
    if (_serieData.grupo == "B") {
      setState(() {
        selectedGroup = 'B';
        listaAMostrar=grupoB;
      });
    }
    if (_serieData.id.startsWith('p')){
      setState(() {
        selectedClasificacion = 'pl';
      });
    }
    else if (_serieData.id.startsWith('g')){
      setState(() {
        selectedClasificacion = 'gr';
      });
    }
    await _fetchPartidosPrevios();
    _loadingSerie = false;
    _fetchClasificacionData();
  }

  void _fetchPartidoIds() async {
    setState(() {
      _loadingPartidos = true;
    });

    var partidosRef = FirebaseFirestore.instance
        .collection('competition')
        .doc(widget.competition_id)
        .collection('series')
        .doc(widget.id)
        .collection('partido')
        .get();

    //aqui hacer una instancia con lo ultimo, importante que sea STREAM(o similar) pq quiero que se actualizen automaticamente

    var partidoSnapshot = await partidosRef;
    var partidosData = partidoSnapshot.docs.map((doc) {
      return PartidoData(
        id: doc.id,
        ladoAzul: doc['lado_azul'],
        ladoRojo: doc['lado_rojo'],
        ganador: doc['ganador'],
          en_directo: doc.data().containsKey("en_directo") ? doc['en_directo'] : false
      );
    }).toList();

    setState(() {
      _partidoIds = partidosData;
      _loadingPartidos = false;
    });
  }

  // Método para cargar los partidos previos
  Future<void> _fetchPartidosPrevios() async {
    setState(() {
      _loadingPartidos2 = true;
    });

    List<SerieData> partidosPrevios = [];

    // Realizar la consulta a Firestore
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collectionGroup('series')
        .where('jugado', isEqualTo: true)
        .where('equipo1', isEqualTo: _serieData.equipo1)
        .where('equipo2', isEqualTo: _serieData.equipo2)
        .where('hora', isLessThan: _serieData.hora) // Filtrar por fecha anterior al partido actual
        .get();

    QuerySnapshot querySnapshot2 = await FirebaseFirestore.instance
        .collectionGroup('series')
        .where('jugado', isEqualTo: true)
        .where('equipo1', isEqualTo: _serieData.equipo2)
        .where('equipo2', isEqualTo: _serieData.equipo1)
        .where('hora', isLessThan: _serieData.hora) // Filtrar por fecha anterior al partido actual
        .get();

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      final competitionDoc = await doc.reference.parent.parent?.get();
      final competitionName = competitionDoc?.data()?['nombre'];
      final competitionID = competitionDoc!.id;
      partidosPrevios.add(SerieData(
        equipo1: doc['equipo1'],
        equipo2: doc['equipo2'],
        competitionName: competitionName ?? "", // Si competitionName es null, establecer un valor predeterminado
        competitionID:competitionID,
        jugado: doc['jugado'],
        hora: (doc['hora'] as Timestamp).toDate(),
        id: doc.id,
        ganador:doc['ganador'],
        equipo1Count:int.parse(doc['equipo1Count']),
        equipo2Count:int.parse(doc['equipo2Count']),
          en_directo:false
      ));
    }

    for (QueryDocumentSnapshot doc in querySnapshot2.docs) {
      final competitionDoc = await doc.reference.parent.parent?.get();
      final competitionName = competitionDoc?.data()?['nombre'];
      final competitionID = competitionDoc!.id;
      partidosPrevios.add(SerieData(
        equipo1: doc['equipo1'],
        equipo2: doc['equipo2'],
        competitionName: competitionName ?? "", // Si competitionName es null, establecer un valor predeterminado
        competitionID:competitionID,
        jugado: doc['jugado'],
        hora: (doc['hora'] as Timestamp).toDate(),
        id: doc.id,
        ganador:doc['ganador'],
        equipo1Count:int.parse(doc['equipo1Count']),
        equipo2Count:int.parse(doc['equipo2Count']),
          en_directo:false
      ));
    }

    // Ordenar la lista de partidos previos por fecha en orden descendente
    partidosPrevios.sort((a, b) => b.hora.compareTo(a.hora));

    int ganado1 = await contarSeriesGanadas(_serieData.equipo1,partidosPrevios);
    int ganado2 = await contarSeriesGanadas(_serieData.equipo2,partidosPrevios);


    // Limitar la lista a solo los primeros 5 elementos si hay más de 5 elementos
    if (partidosPrevios.length > 5) {
      partidosPrevios = partidosPrevios.sublist(0, 5);
    }

    // Calcular el número de series ganadas por cada equipo


    setState(() {
      _partidosPrevios = partidosPrevios;
      _loadingPartidos2 = false;
      _ganado1 = ganado1;
      _ganado2 = ganado2;
    });
  }

  int contarSeriesGanadas(String equipo, List<SerieData> partidosPrevios) {
    int count = 0;
    for (SerieData serie in partidosPrevios) {
        // Mientras el ganador sea nulo, esperar antes de continuar.
      if (serie.ganador == equipo) {
          count++;
      }
    }
    return count;
  }

  // Widget para mostrar los últimos 5 partidos de cada equipo en una tabla
  // Widget para mostrar los últimos 5 partidos de cada equipo en una tabla
  Widget _buildUltimosPartidos() {
    print("a");
    return FutureBuilder<List<Map<String, SerieData>>>(
      future: _fetchUltimosPartidos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Muestra un indicador de carga mientras se obtienen los datos
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}'); // Muestra un mensaje de error si hay un error
        } else {
          List<Map<String, SerieData>> ultimosPartidos = snapshot.data!;

          // Envuelve la DataTable en un Container para establecer el ancho
          return Container(
            width: MediaQuery.of(context).size.width, // Ajusta el ancho deseado
            child: DataTable(
              horizontalMargin: 10,
              columnSpacing: 10,
              border: TableBorder(
                top: BorderSide.none,  // Elimina el borde superior
                bottom: BorderSide(width: 2, color: Color(0xff6200ff)),
                horizontalInside: BorderSide(width: 2, color: Color(0xff6200ff)),
                verticalInside: BorderSide(width: 2, color: Color(0xff6200ff)),
              ),
              headingRowHeight: 0,
              columns: [
                DataColumn(label: Text('${_serieData.equipo1}')),
                DataColumn(label: Text('${_serieData.equipo2}')),
              ],
              rows: List<DataRow>.generate(
                5,
                    (index) {
                  Map<String, SerieData> partido = ultimosPartidos[index];
                  return DataRow(
                    cells: [
                      DataCell(
                        partido[_serieData.equipo1]!.equipo1 != "Null"
                            ? GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SerieDetailScreen(
                                  id: partido[_serieData.equipo1]!.id,
                                  competition_id: partido[_serieData.equipo1]!.competitionID,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Image.asset(
                                partido[_serieData.equipo1]!.equipo1 == _serieData.equipo1 ?
                                'assets/${partido[_serieData.equipo1]!.equipo2.toLowerCase()}.png': 'assets/${partido[_serieData.equipo1]!.equipo1.toLowerCase()}.png', // Ruta de la imagen que quieres mostrar
                                width: 24.0, // Ancho de la imagen (puedes ajustar según tus necesidades)
                                height: 24.0, // Altura de la imagen (puedes ajustar según tus necesidades)
                              ),
                              SizedBox(width: 8.0),
                              // Rectángulo verde con "W" a la izquierda
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    '${partido[_serieData.equipo1]!.equipo1} ${partido[_serieData.equipo1]!.equipo1Count} - ${partido[_serieData.equipo1]!.equipo2Count} ${partido[_serieData.equipo1]!.equipo2}',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(color: Color(0xff6200ff),fontFamily: 'Sequel100', fontSize: 8.5)
                                ),
                                Text(
                                    '${partido[_serieData.equipo1]!.competitionName}',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(color: Color(0xff6200ff),fontFamily: 'SequelSans', fontSize: 8.0)
                                ),
                              ],
                          )
                              ),

                              // Espacio entre el rectángulo y el texto
                              SizedBox(width: 8),
                              // Texto pegado a la derecha
                              Container(
                                width: 30,  // Ajusta el ancho según sea necesario
                                height: 30, // Ajusta la altura según sea necesario
                                color: partido[_serieData.equipo1]!.ganador == _serieData.equipo1 ? Color(0xff04e2bc) : Color(0xffe2046c),  // Color verde
                                child: Center(
                                  child: Text(
                                    partido[_serieData.equipo1]!.ganador == _serieData.equipo1 ? 'W' : 'L',
                                    style: TextStyle(
                                      color: Colors.white, // Color del texto "W" o "L"
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            : SizedBox(),
                      ),
                      DataCell(
                        partido[_serieData.equipo2]!.equipo1 != "Null"
                            ? GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SerieDetailScreen(
                                  id: partido[_serieData.equipo2]!.id,
                                  competition_id: partido[_serieData.equipo2]!.competitionID,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              // Rectángulo verde con "W" a la izquierda

                              Container(
                                width: 30,  // Ajusta el ancho según sea necesario
                                height: 30, // Ajusta la altura según sea necesario
                                color: partido[_serieData.equipo2]!.ganador == _serieData.equipo2 ? Color(0xff04e2bc) : Color(0xffe2046c),  // Color verde
                                child: Center(
                                  child: Text(
                                    partido[_serieData.equipo2]!.ganador == _serieData.equipo2 ? 'W' : 'L',
                                    style: TextStyle(
                                      color: Colors.white, // Color del texto "W"
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              // Espacio entre el rectángulo y el texto
                              SizedBox(width: 8),
                              // Texto pegado a la derecha
                              Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                          '${partido[_serieData.equipo2]!.equipo1} ${partido[_serieData.equipo2]!.equipo1Count} - ${partido[_serieData.equipo2]!.equipo2Count} ${partido[_serieData.equipo2]!.equipo2}',
                                          textAlign: TextAlign.left,
                                          style: TextStyle(color: Color(0xff6200ff),fontFamily: 'Sequel100', fontSize: 8.5)
                                      ),
                                      Text(
                                          '${partido[_serieData.equipo2]!.competitionName}',
                                          textAlign: TextAlign.left,
                                          style: TextStyle(color: Color(0xff6200ff),fontFamily: 'SequelSans', fontSize: 8.0)
                                      ),
                                    ],
                                  )
                              ),
                              SizedBox(width: 8),
                              Image.asset(
                                partido[_serieData.equipo2]!.equipo1 == _serieData.equipo2 ?
                                'assets/${partido[_serieData.equipo2]!.equipo2.toLowerCase()}.png': 'assets/${partido[_serieData.equipo2]!.equipo1.toLowerCase()}.png', // Ruta de la imagen que quieres mostrar
                                width: 24.0, // Ancho de la imagen (puedes ajustar según tus necesidades)
                                height: 24.0, // Altura de la imagen (puedes ajustar según tus necesidades)
                              ),
                            ],
                          ),
                        )
                            : SizedBox(),
                      ),

                    ],
                  );
                },
              ),
            ),
          );
        }
      },
    );
  }

// Función para obtener los últimos 5 partidos de cada equipo
  Future<List<Map<String, SerieData>>> _fetchUltimosPartidos() async {
    DateTime fechaActual = _serieData.hora;
    List<Map<String, SerieData>> ultimosPartidos = [];

    // Realizar las consultas para los últimos partidos de ambos equipos
    QuerySnapshot querySnapshot1 = await FirebaseFirestore.instance
        .collectionGroup('series')
        .where('jugado', isEqualTo: true)
        .where('hora', isLessThan: fechaActual)
        .where('equipo1', isEqualTo: _serieData.equipo1)
        .orderBy('hora', descending: true)
        .limit(5)
        .get();

    QuerySnapshot querySnapshot1Inverted = await FirebaseFirestore.instance
        .collectionGroup('series')
        .where('jugado', isEqualTo: true)
        .where('hora', isLessThan: fechaActual)
        .where('equipo2', isEqualTo: _serieData.equipo1)
        .orderBy('hora', descending: true)
        .limit(5)
        .get();

    QuerySnapshot querySnapshot2 = await FirebaseFirestore.instance
        .collectionGroup('series')
        .where('jugado', isEqualTo: true)
        .where('hora', isLessThan: fechaActual)
        .where('equipo2', isEqualTo: _serieData.equipo2)
        .orderBy('hora', descending: true)
        .limit(5)
        .get();

    QuerySnapshot querySnapshot2Inverted = await FirebaseFirestore.instance
        .collectionGroup('series')
        .where('jugado', isEqualTo: true)
        .where('hora', isLessThan: fechaActual)
        .where('equipo1', isEqualTo: _serieData.equipo2)
        .orderBy('hora', descending: true)
        .limit(5)
        .get();

    // Combinar los resultados de todas las consultas
    List<QueryDocumentSnapshot> allDocs = [];
    List<QueryDocumentSnapshot> allDocs2 = [];
    allDocs.addAll(querySnapshot1.docs);
    allDocs.addAll(querySnapshot1Inverted.docs);
    allDocs2.addAll(querySnapshot2.docs);
    allDocs2.addAll(querySnapshot2Inverted.docs);

    // Ordenar los documentos por fecha en orden descendente
    allDocs.sort((a, b) => (b['hora'] as Timestamp).compareTo(a['hora'] as Timestamp));
    allDocs2.sort((a, b) => (b['hora'] as Timestamp).compareTo(a['hora'] as Timestamp));

    // Limitar la cantidad de documentos combinados a 5
    allDocs = allDocs.take(5).toList();
    allDocs2 = allDocs2.take(5).toList();

    // Organizar los resultados en una lista de mapas
    for (int i = 0; i < 5; i++) {
      SerieData partido1;
      SerieData partido2;

      if (i < allDocs.length) {
        final competitionDoc = await allDocs[i].reference.parent.parent?.get();
        final competitionName = competitionDoc?.data()?['nombre'];
        final competitionID = competitionDoc!.id;
        partido1 = SerieData(
          equipo1: allDocs[i]['equipo1'],
          equipo2: allDocs[i]['equipo2'],
          competitionName: competitionName,
          competitionID: competitionID,
          jugado: allDocs[i]['jugado'],
          hora: allDocs[i]['hora'].toDate(),
          id: allDocs[i].id,
          ganador: allDocs[i]['ganador'],
          equipo1Count: int.parse(allDocs[i]['equipo1Count']),
          equipo2Count: int.parse(allDocs[i]['equipo2Count']),
            en_directo:false
        );
      } else {
        partido1 = SerieData(
          equipo1: "Null",
          equipo2: "Null",
          competitionName: '',
          competitionID: "",
          jugado: false,
          hora: DateTime.now(),
          id: '',
          ganador: "Null",
          equipo1Count: 0,
          equipo2Count: 0,
            en_directo:false,
        );
      }

      if (i < allDocs2.length) {
        final competitionDoc2 = await allDocs2[i].reference.parent.parent?.get();
        final competitionName2 = competitionDoc2?.data()?['nombre'];
        final competitionID2 = competitionDoc2!.id;
        partido2 = SerieData(
          equipo1: allDocs2[i]['equipo1'],
          equipo2: allDocs2[i]['equipo2'],
          competitionName: competitionName2,
          competitionID: competitionID2,
          jugado: allDocs2[i]['jugado'],
          hora: allDocs2[i]['hora'].toDate(),
          id: allDocs2[i].id,
          ganador: allDocs2[i]['ganador'],
          equipo1Count: int.parse(allDocs2[i]['equipo1Count']),
          equipo2Count: int.parse(allDocs2[i]['equipo2Count']),
            en_directo: false
        );
      } else {
        partido2 = SerieData(
          equipo1: "Null",
          equipo2: "Null",
          competitionName: '',
          competitionID: "",
          jugado: false,
          hora: DateTime.now(),
          id: '',
          ganador: "Null",
          equipo1Count: 0,
          equipo2Count: 0,
          en_directo:false,
        );
      }

      Map<String, SerieData> partido = {
        _serieData.equipo1: partido1,
        _serieData.equipo2: partido2,
      };

      ultimosPartidos.add(partido);
      //print(partido);
    }

    return ultimosPartidos;
  }

  Widget _buildComparacionPlantillas() {
    return FutureBuilder(
      future: _fetchDatosPlantillas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<Jugador> jugadoresEquipo1 = snapshot.data![0];
          List<Jugador> jugadoresEquipo2 = snapshot.data![1];

          return Container(
              width: MediaQuery.of(context).size.width, // Ajusta el ancho deseado
            child:DataTable(
              columnSpacing: 10,
              border: TableBorder(
                top: BorderSide.none,  // Elimina el borde superior
                bottom: BorderSide(width: 2, color: Colors.white),
                horizontalInside: BorderSide(width: 2, color: Colors.white),
                verticalInside: BorderSide(width: 2, color: Colors.white),
              ),
              headingRowHeight: 0,
              columns: [
                DataColumn(label: Text('Equipo 1')),
                DataColumn(label: Text('Equipo 2')),
              ],
              rows: List<DataRow>.generate(
                max(jugadoresEquipo1.length, jugadoresEquipo2.length),
                    (index) {
                  return DataRow(
                    cells: [
                      DataCell(
                        index < jugadoresEquipo1.length
                            ? GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayerDetailPage(ign: jugadoresEquipo1[index].ign),
                              ),
                            );
                          },
                          child:
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 120.0,
                                child:Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      jugadoresEquipo1[index].ign,
                                      style: TextStyle(
                                        fontSize: 9.0,
                                        fontFamily: "Sequel100",
                                        color: Color(0xff6200ff),
                                      ),
                                    ),
                                    Text(
                                      jugadoresEquipo1[index].posicion,
                                      style: TextStyle(
                                        fontSize: 8.0,
                                        fontFamily: "SequelSans",
                                        color: Color(0xff6200ff),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 5.0),
                              // ClipOval para el círculo
                              Container(
                                width: 45.0,
                                height: 45.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Color(0xff2d0079), // El borde rojo
                                    width: 2.0, // El grosor del borde
                                  ),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 45.0,
                                    height: 45.0,
                                    child: ClipOval(
                                      child: Image.network(
                                        jugadoresEquipo1[index].foto,
                                        fit: BoxFit.cover,
                                      )
                                    ),
                                  ),
                                ),
                              ),
                              // Espacio entre el círculo y el texto
                              // Texto del jugador
                            ],
                          ),
                        )
                            : SizedBox(),
                      ),
                      DataCell(
                        index < jugadoresEquipo2.length
                            ? GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayerDetailPage(ign: jugadoresEquipo2[index].ign),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // ClipOval para el círculo
                              Container(
                                width: 45.0,
                                height: 45.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Color(0xff2d0079), // El borde rojo
                                    width: 2.0, // El grosor del borde
                                  ),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 45.0,
                                    height: 45.0,
                                    child: ClipOval(
                                        child: Image.network(
                                          jugadoresEquipo2[index].foto,
                                          fit: BoxFit.cover,
                                        )
                                    ),
                                  ),
                                ),
                              ),
                              // Espacio entre el círculo y el texto
                              SizedBox(width: 5.0),
                              // Texto del jugador
                              Container(
                                  width: 120.0,
                                  child:Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        jugadoresEquipo2[index].ign,
                                        style: TextStyle(
                                          fontSize: 9.0,
                                          fontFamily: "Sequel100",
                                          color: Color(0xff6200ff),
                                        ),
                                      ),
                                      Text(
                                        jugadoresEquipo2[index].posicion,
                                        style: TextStyle(
                                          fontSize: 8.0,
                                          fontFamily: "SequelSans",
                                          color: Color(0xff6200ff),
                                        ),
                                      ),
                                    ],
                                  )
                              ),
                            ],
                          ),
                        )
                            : SizedBox(),
                      ),

                    ],
                  );
                },
              ),

            )
          );
        }
      },
    );
  }
  Widget _buildComparacionPlantillas2() {
    return FutureBuilder(
      future: _fetchDatosPlantillas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<Jugador> jugadoresEquipo1 = snapshot.data![0];
          List<Jugador> jugadoresEquipo2 = snapshot.data![1];

          return DataTable(
            columns: [
              DataColumn(label: Text('Equipo 1')),
              DataColumn(label: Text('Equipo 2')),
            ],
            rows: List<DataRow>.generate(
              max(jugadoresEquipo1.length, jugadoresEquipo2.length),
                  (index) {
                return DataRow(
                  cells: [
                    DataCell(
                      index < jugadoresEquipo1.length
                          ? GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerDetailPage(ign: jugadoresEquipo1[index].ign),
                            ),
                          );
                        },
                        child: Text(jugadoresEquipo1[index].ign),
                      )
                          : SizedBox(),
                    ),
                    DataCell(
                      index < jugadoresEquipo2.length
                          ? GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerDetailPage(ign: jugadoresEquipo2[index].ign),
                            ),
                          );
                        },
                        child: Text(jugadoresEquipo2[index].ign),
                      )
                          : SizedBox(),
                    ),
                  ],
                );
              },
            ),

          );
        }
      },
    );
  }

  Future<List<List<Jugador>>> _fetchDatosPlantillas() async {
    // Realizar las consultas para obtener los jugadores de cada equipo
    final equipo1Snapshot = await FirebaseFirestore.instance
        .collection('competition')
        .doc(_serieData.competitionID)
        .collection('teams')
        .where('tricode', isEqualTo:_serieData.equipo1)
        .get();

    final equipo2Snapshot = await FirebaseFirestore.instance
        .collection('competition')
        .doc(_serieData.competitionID)
        .collection('teams')
        .where('tricode', isEqualTo: _serieData.equipo2)
        .get();

    // Obtener los jugadores de cada equipo
    List<Jugador> jugadoresEquipo1 = [];
    List<Jugador> jugadoresEquipo2 = [];

    // Función para ordenar los jugadores por su posición
    void ordenarJugadoresPorPosicion(List<Jugador> jugadores) {
      jugadores.sort((a, b) {
        // Definir el orden de las posiciones
        final Map<String, int> ordenPosiciones = {
          'TOP': 0,
          'JNG': 1,
          'MID': 2,
          'BOT': 3,
          'SUP': 4,
        };
        return ordenPosiciones[a.posicion]!.compareTo(ordenPosiciones[b.posicion]!);
      });
    }

    // Obtener y ordenar los jugadores del equipo 1
    for (final doc in equipo1Snapshot.docs) {
      final jugadoresSnapshot = await doc.reference.collection('players').get();
      for (final jugadorDoc in jugadoresSnapshot.docs) {
        // Realizar una consulta adicional para obtener la foto del jugador
        final jugadorInfoDoc = await FirebaseFirestore.instance
            .collection('players_info')
            .doc(jugadorDoc['ign'])
            .get();

        // Obtener la foto del documento si existe
        final foto = jugadorInfoDoc.exists ? jugadorInfoDoc['foto'] : "null";
        // Crear una instancia de Jugador con la información obtenida
        jugadoresEquipo1.add(Jugador(
          jugadorDoc['ign'],
          jugadorDoc['posicion'],
          foto, // Añadir el campo de la foto a la instancia de Jugador
        ));
      }
    }
    ordenarJugadoresPorPosicion(jugadoresEquipo1);

    for (final doc in equipo2Snapshot.docs) {
      final jugadoresSnapshot = await doc.reference.collection('players').get();
      for (final jugadorDoc in jugadoresSnapshot.docs) {
        // Realizar una consulta adicional para obtener la foto del jugador
        final jugadorInfoDoc = await FirebaseFirestore.instance
            .collection('players_info')
            .doc(jugadorDoc['ign'])
            .get();
        // Obtener la foto del documento si existe
        final foto = jugadorInfoDoc.exists ? jugadorInfoDoc['foto'] : "null";

        // Crear una instancia de Jugador con la información obtenida
        jugadoresEquipo2.add(Jugador(
          jugadorDoc['ign'],
          jugadorDoc['posicion'],
          foto, // Añadir el campo de la foto a la instancia de Jugador
        ));
      }
    }

    ordenarJugadoresPorPosicion(jugadoresEquipo2);

    return [jugadoresEquipo1, jugadoresEquipo2];
  }

  Widget _buildClasificacion1() {
    return FutureBuilder<List<List<dynamic>>>(
      future: _getClasificacionData1(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error al cargar los datos');
        } else {
          List<List<dynamic>> clasificacion = snapshot.data!;
          return Container(
            width: 400,
            child: DataTable(
              border: TableBorder(
                top: BorderSide.none, // Elimina el borde superior
                bottom: BorderSide(width: 2, color: Colors.white),
                horizontalInside: BorderSide(width: 2, color: Colors.white),
              ),
              columns: [
                DataColumn(label: Text('')),
                DataColumn(
                  label: Text('V', style: TextStyle(fontSize: 13.0, fontFamily: "SequelSans", color: Color(0xff6200ff))),
                ),
                DataColumn(
                  label: Text('D', style: TextStyle(fontSize: 13.0, fontFamily: "SequelSans", color: Color(0xff6200ff))),
                ),
              ],
              rows: clasificacion.map((teamData) {
                int index = clasificacion.indexOf(teamData) + 1;

                // Define un color verde con baja opacidad para las posiciones de 1 a 8
                Color rowColor;
                if (index >= 1 && index <= 8) {
                  rowColor = Color(0xff6200ff); // Verde con baja opacidad
                }else{ rowColor = Colors.white;}

                // Define el estilo de texto con color blanco si la fila está en posiciones de 1 a 8
                TextStyle textStyle;
                TextStyle textStyle2;
                if (index >= 1 && index <= 8) {
                  textStyle = TextStyle(fontSize: 13.0, fontFamily: "SequelSans", color: Colors.white);
                  textStyle2 = TextStyle(fontSize: 13.0, fontFamily: "Sequel100", color: Colors.white);
                } else {
                  textStyle = TextStyle(fontSize: 13.0, fontFamily: "SequelSans", color: Color(0xff6200ff));
                  textStyle2 = TextStyle(fontSize: 13.0, fontFamily: "Sequel100", color: Color(0xff6200ff));
                }

                return DataRow(
                  color: rowColor != null ? MaterialStateColor.resolveWith((states) => rowColor) : null,
                  cells: [
                    DataCell(
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeamDetailPage(tricode: teamData[0]),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(index.toString(), style: textStyle),
                            SizedBox(width: 20),
                            Image.asset(index >= 1 && index <= 8 ? 'assets/${teamData[0].toLowerCase()}2.png' : 'assets/${teamData[0].toLowerCase()}.png', width: 30, height: 30),
                            SizedBox(width: 20),
                            Text(teamData[0], style: textStyle),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text(teamData[1].toString(), style: textStyle)),
                    DataCell(Text(teamData[2].toString(), style: textStyle)),
                  ],
                );
              }).toList(),
            ),
          );

        }
      },
    );
  }

  Future<List<List<dynamic>>> _getClasificacionData1() async {
    List<List<dynamic>> clasificacion = [];
    try {
      // Consulta para obtener los equipos y sus IDs
      QuerySnapshot equiposSnapshot = await FirebaseFirestore.instance
          .collection('competition')
          //cambiar a .doc(_serieData.competitionID) cuando este en la DB
          .doc("lec_2023_3")
          .collection('teams')
          .get();

      // Inicializa los diccionarios de victorias y derrotas con 0 para cada equipo
      Map<String, int> victorias = {};
      Map<String, int> derrotas = {};
      equiposSnapshot.docs.forEach((equipo) {
        victorias[equipo.id] = 0;
        derrotas[equipo.id] = 0;
      });

      // Consulta para obtener las series
      QuerySnapshot seriesSnapshot = await FirebaseFirestore.instance
          .collection('competition')
          .doc(_serieData.competitionID)
          .collection('series')
          .where('hora', isLessThanOrEqualTo: _serieData.hora)
          .get();

      // Procesa las series para calcular victorias y derrotas
      seriesSnapshot.docs.forEach((x) {
        Map<String, dynamic> data = x.data() as Map<String, dynamic>;
        String ganador = data["ganador"];
        String equipo1 = data["equipo1"];
        String equipo2 = data["equipo2"];

        // Filtrar partidas cuyo ID empiece por 'j'
        if (x.id.startsWith('s')) {
          // Actualiza el diccionario de victorias y derrotas
          if (ganador == equipo1) {
            victorias[equipo1] = (victorias[equipo1] ?? 0) + 1;
            derrotas[equipo2] = (derrotas[equipo2] ?? 0) + 1;
          } else if (ganador == equipo2) {
            victorias[equipo2] = (victorias[equipo2] ?? 0) + 1;
            derrotas[equipo1] = (derrotas[equipo1] ?? 0) + 1;
          }
        }
      });

      // Ordena los equipos según el número de victorias y derrotas
      List<MapEntry<String, int>> sortedTeams = victorias.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Crea la lista de listas en el formato deseado
      clasificacion = sortedTeams.map((entry) {
        return [entry.key, entry.value, derrotas[entry.key] ?? 0];
      }).toList();

      return clasificacion;
    } catch (error) {
      throw error;
    }
  }

  Widget _buildClasificacion2() {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height), // Limitar la altura
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedGroup = 'A';
                    listaAMostrar = grupoA;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedGroup == 'A' ? Color(0xff6200ff) : null,
                  elevation: 0.1,
                    side: BorderSide(width: 1.7, color: Color(0xff6200ff))// Color de fondo si es el grupo activo
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                  ),
                  child: Text('Grupo A',style:TextStyle(fontFamily: "SequelSans",color: selectedGroup == 'A' ? Colors.white : Color(0xff6200ff)))),
              ),
              SizedBox(width: 20), // Añadir espacio entre los botones
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedGroup = 'B';
                    listaAMostrar = grupoB;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedGroup == 'B' ? Color(0xff6200ff) : null, // Color de fondo si es el grupo activo
                    elevation: 0.1,
                    side: BorderSide(width: 1.7, color: Color(0xff6200ff))// Color de fondo si es el grupo activo
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: TextTheme(button: TextStyle(color: selectedGroup == 'B' ? Colors.white : null)), // Color del texto si es el grupo activo
                  ),
                  child: Text('Grupo B',style:TextStyle(fontFamily: "SequelSans",color: selectedGroup == 'B' ? Colors.white : Color(0xff6200ff)))),
                ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('Ronda 1', style: TextStyle(fontFamily: "SequelSans",color: Color(0xff6200ff))), // Etiqueta "R1"
                      SizedBox(height: 5), // Espacio entre la etiqueta y la lista
                      _buildColumnForRTypeMatches('r1'), // Columna para los partidos que contienen "r1"
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Ronda 2', style: TextStyle(fontFamily: "SequelSans",color: Color(0xff6200ff))), // Etiqueta "R2"
                      SizedBox(height: 5), // Espacio entre la etiqueta y la lista
                      _buildColumnForRTypeMatches('r2'), // Columna para los partidos que contienen "r2"
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildColumnForRTypeMatches(String rType) {
    // Filtrar los partidos según el tipo de "r"
    List<SerieData> matches = listaAMostrar.where((serie) => serie.id.contains(rType)).toList();

    // Construir una lista de widgets ListTile para los partidos correspondientes al tipo de "r"
    List<Widget> matchWidgets = matches.map((match) {
      if (match.hora.isAfter(_serieData.hora)) {
        // Si el partido aún no se ha jugado, mostrar "TBD - TBD"
        return ListTile(
          title: Column(
            children: [
              Row(children:[
                Image.asset('assets/${match.equipo1.toLowerCase()}.png',width: 24.0,height: 24.0,),
                SizedBox(width: 8),
                Text('${match.equipo1} -',style: TextStyle(fontFamily: "Sequel100",color: Color(0xff6200ff))),
              ],),
              Row(children:[
                Image.asset('assets/${match.equipo2.toLowerCase()}.png',width: 24.0,height: 24.0,),
                SizedBox(width: 8),
                Text('${match.equipo2} -',style: TextStyle(fontFamily: "Sequel100",color: Color(0xff6200ff)))
              ],),
            ],
          ),

          onTap: () {
            // Navegar a la pantalla de detalle de la serie con los datos de la serie seleccionada
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SerieDetailScreen(
                  id: match.id,
                  competition_id: match.competitionID,
                ),
              ),
            );
          },
          //hacer que vaya
        );
      } else if  (match.hora == (_serieData.hora)){
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          tileColor: Color(0xff6200ff), // Cambia el color de fondo a verde
          title: Column(
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/${match.equipo1.toLowerCase()}2.png',
                    width: 24.0,
                    height: 24.0,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${match.equipo1} ${match.equipo1Count}',
                    style: TextStyle(
                      fontFamily: "Sequel100",
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Image.asset(
                    'assets/${match.equipo2.toLowerCase()}2.png',
                    width: 24.0,
                    height: 24.0,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${match.equipo2} ${match.equipo2Count}',
                    style: TextStyle(
                      fontFamily: "Sequel100",
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        // Si el partido ya se ha jugado, mostrar los equipos y el resultado
        return ListTile(
          title: Column(
            children: [
              Row(children:[
                Image.asset('assets/${match.equipo1.toLowerCase()}.png',width: 24.0,height: 24.0,),
                SizedBox(width: 8),
                Text('${match.equipo1} ${match.equipo1Count}',style: TextStyle(fontFamily: "Sequel100",color: Color(0xff6200ff))),
              ],),
              Row(children:[
                Image.asset('assets/${match.equipo2.toLowerCase()}.png',width: 24.0,height: 24.0,),
                SizedBox(width: 8),
                Text('${match.equipo2} ${match.equipo2Count}',style: TextStyle(fontFamily: "Sequel100",color: Color(0xff6200ff)))
              ],),
            ],
          ),
          onTap: () {
            // Navegar a la pantalla de detalle de la serie con los datos de la serie seleccionada
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SerieDetailScreen(
                  id: match.id,
                  competition_id: match.competitionID,
                ),
              ),
            );
          },
        );
      }
    }).toList();

    // Devolver una columna que contiene los partidos correspondientes al tipo de "r"
    return Container(
      height: MediaQuery.of(context).size.height * 0.5, // Establece una altura fija o utiliza otro método para establecerla
      child: ListView(
        children: matchWidgets,

      ),
    );
  }

  Future<void> _fetchClasificacionData() async {
    try {
      List<SerieData> clasificacion = await _getClasificacionData2();
      setState(() {
        // Filtrar las series según el grupo
        grupoA = clasificacion.where((serie) => serie.grupo == "A").toList();
        grupoB = clasificacion.where((serie) => serie.grupo == "B").toList();

        // Si _serieData.grupo es B, selecciona automáticamente el grupo B
        // Establecer la lista inicial según el grupo seleccionado
        listaAMostrar = selectedGroup == 'A' ? grupoA : grupoB;
      });
    } catch (error) {
      print('Error al cargar los datos de clasificación: $error');
    }
  }
  Future<List<SerieData>> _getClasificacionData2() async {
    List<SerieData> clasificacion = [];
    try {
      // Consulta para obtener los equipos y sus IDs
      QuerySnapshot equiposSnapshot = await FirebaseFirestore.instance
          .collection('competition')
          .doc("lec_2023_3")
          .collection('teams')
          .get();

      // Consulta para obtener las series
      QuerySnapshot seriesSnapshot = await FirebaseFirestore.instance
          .collection('competition')
          .doc(_serieData.competitionID)
          .collection('series')
          //.where('hora', isLessThanOrEqualTo: _serieData.hora)
          .get();

      // Procesa las series para calcular victorias y derrotas
      seriesSnapshot.docs.forEach((x) {
        Map<String, dynamic> data = x.data() as Map<String, dynamic>;
        String ganador = data["ganador"];
        String equipo1 = data["equipo1"];
        String equipo2 = data["equipo2"];
        int equipo1Count = int.parse(data["equipo1Count"]);
        int equipo2Count = int.parse(data["equipo2Count"]);
        String grupo = data["grupo"] ?? 'no';
        bool en_directo = data["en_directo"] ?? false;
        // Filtrar partidas cuyo ID empiece por 'g'
        if (x.id.startsWith('g')) {
          print(grupo);
          // Actualiza el diccionario de victorias y derrotas

          SerieData serie = SerieData(
            equipo1: equipo1,
            equipo2: equipo2,
            competitionName: _serieData.competitionName,
            competitionID: _serieData.competitionID,
            jugado: data["jugado"],
            hora: data["hora"].toDate(),
            id: x.id,
            ganador: ganador,
            equipo1Count: equipo1Count,
            equipo2Count: equipo2Count,
            grupo:grupo,
              en_directo:en_directo
          );

          clasificacion.add(serie);
        }
      });
      print("?");
      print(clasificacion);
      return clasificacion;
    } catch (error) {
      throw error;
    }
  }

  Widget _buildClasificacion3() {
    // Llamar a _getClasificacionData3() una vez fuera del Widget para evitar llamadas múltiples
    return FutureBuilder<List<SerieData>>(
      future: _getClasificacionData3(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error al cargar los datos');
        } else {
          List<SerieData> data = snapshot.data!;

          // Filtrar las series del grupo 1
          List<SerieData> grupo1 = data.toList();
          print("lista");
          print(grupo1);

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height), // Limitar la altura
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('R1',style: TextStyle(fontFamily: "SequelSans",color: Color(0xff6200ff))), // Título para la columna R1
                      _buildColumnForPLypeMatches('pl1', grupo1), // Mostrar las partidas de R1
                    ],
                  ),
                ),
                SizedBox(width: 20), // Espacio entre las columnas
                Expanded(
                  child: Column(
                    children: [
                      Text('R2',style: TextStyle(fontFamily: "SequelSans",color: Color(0xff6200ff))), // Título para la columna R2
                      _buildColumnForPLypeMatches('pl2', grupo1), // Mostrar las partidas de R2
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('R3',style: TextStyle(fontFamily: "SequelSans",color: Color(0xff6200ff))), // Título para la columna R3
                      _buildColumnForPLypeMatches('pl3', grupo1), // Mostrar las partidas de R3
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
  Widget _buildColumnForPLypeMatches(String rType, List<SerieData> matches) {
    // Filtrar los partidos según el tipo de "r"
    List<SerieData> filteredMatches = matches.where((serie) => serie.id.contains(rType)).toList();

    // Construir una lista de widgets ListTile para los partidos correspondientes al tipo de "r"
    List<Widget> matchWidgets = filteredMatches.map((match) {
      if (match.hora.isAfter(_serieData.hora)) {
        // Si el partido aún no se ha jugado, mostrar "TBD - TBD"
        return ListTile(
          title: Column(
            children: [
              Row(children:[
                Image.asset('assets/${match.equipo1.toLowerCase()}.png',width: 20.0,height: 20.0,),
                SizedBox(width: 5),
                Text('${match.equipo1} -',style: TextStyle(fontFamily: "Sequel100",color: Color(0xff6200ff),fontSize: 11)),
              ],),
              Row(children:[
                Image.asset('assets/${match.equipo2.toLowerCase()}.png',width: 20.0,height: 20.0,),
                SizedBox(width: 5),
                Text('${match.equipo2} -',style: TextStyle(fontFamily: "Sequel100",color: Color(0xff6200ff),fontSize: 11))
              ],),
            ],
          ),

          onTap: () {
            // Navegar a la pantalla de detalle de la serie con los datos de la serie seleccionada
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SerieDetailScreen(
                  id: match.id,
                  competition_id: match.competitionID,
                ),
              ),
            );
          },
          //hacer que vaya
        );
      } else if  (match.hora == (_serieData.hora)){
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          tileColor: Color(0xff6200ff), // Cambia el color de fondo a verde
          title: Column(
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/${match.equipo1.toLowerCase()}2.png',
                    width: 20.0,
                    height: 20.0,
                  ),
                  SizedBox(width: 5),
                  Text(
                    '${match.equipo1} ${match.equipo1Count}',
                    style: TextStyle(
                      fontFamily: "Sequel100",
                      color: Colors.white,
                        fontSize: 11
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Image.asset(
                    'assets/${match.equipo2.toLowerCase()}2.png',
                    width: 20.0,
                    height: 20.0,
                  ),
                  SizedBox(width: 5),
                  Text(
                    '${match.equipo2} ${match.equipo2Count}',
                    style: TextStyle(
                      fontFamily: "Sequel100",
                      color: Colors.white,
                        fontSize: 11
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        // Si el partido ya se ha jugado, mostrar los equipos y el resultado
        return ListTile(
          title: Column(
            children: [
              Row(children:[
                Image.asset('assets/${match.equipo1.toLowerCase()}.png',width: 20.0,height: 20.0,),
                SizedBox(width: 5),
                Text('${match.equipo1} ${match.equipo1Count}',style: TextStyle(fontFamily: "Sequel100",color: Color(0xff6200ff),fontSize: 11)),
              ],),
              Row(children:[
                Image.asset('assets/${match.equipo2.toLowerCase()}.png',width: 20.0,height: 20.0,),
                SizedBox(width: 5),
                Text('${match.equipo2} ${match.equipo2Count}',style: TextStyle(fontFamily: "Sequel100",color: Color(0xff6200ff),fontSize: 11))
              ],),
            ],
          ),
          onTap: () {
            // Navegar a la pantalla de detalle de la serie con los datos de la serie seleccionada
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SerieDetailScreen(
                  id: match.id,
                  competition_id: match.competitionID,
                ),
              ),
            );
          },
        );
      }
    }).toList();

    // Devolver una columna que contiene los partidos correspondientes al tipo de "r"
    return Container(
      height: MediaQuery.of(context).size.height * 0.5, // Establece una altura fija o utiliza otro método para establecerla
      child: ListView(
        children: matchWidgets,
      ),
    );
  }
  Future<List<SerieData>> _getClasificacionData3() async {
    List<SerieData> clasificacion = [];
    try {
      // Consulta para obtener los equipos y sus IDs
      QuerySnapshot equiposSnapshot = await FirebaseFirestore.instance
          .collection('competition')
          .doc("lec_2023_3")
          .collection('teams')
          .get();

      // Consulta para obtener las series
      QuerySnapshot seriesSnapshot = await FirebaseFirestore.instance
          .collection('competition')
          .doc(_serieData.competitionID)
          .collection('series')
      //.where('hora', isLessThanOrEqualTo: _serieData.hora)
          .get();

      // Procesa las series para calcular victorias y derrotas
      seriesSnapshot.docs.forEach((x) {
        Map<String, dynamic> data = x.data() as Map<String, dynamic>;
        String ganador = data["ganador"];
        String equipo1 = data["equipo1"];
        String equipo2 = data["equipo2"];
        int equipo1Count = int.parse(data["equipo1Count"]);
        int equipo2Count = int.parse(data["equipo2Count"]);
        String grupo = data["grupo"] ?? 'no';
        bool en_directo= data["en_directo"] ?? false;

        // Filtrar partidas cuyo ID empiece por 'g'
        if (x.id.startsWith('p')) {
          print(grupo);
          // Actualiza el diccionario de victorias y derrotas

          SerieData serie = SerieData(
              equipo1: equipo1,
              equipo2: equipo2,
              competitionName: _serieData.competitionName,
              competitionID: _serieData.competitionID,
              jugado: data["jugado"],
              hora: data["hora"].toDate(),
              id: x.id,
              ganador: ganador,
              equipo1Count: equipo1Count,
              equipo2Count: equipo2Count,
              grupo:grupo,
              en_directo:en_directo
          );

          clasificacion.add(serie);
        }
      });
      print("??");
      print(clasificacion);
      return clasificacion;
    } catch (error) {
      throw error;
    }
  }

// Llamar a _buildUltimosPartidos() en el lugar adecuado dentro de tu widget build()

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff6200ff),
        ),
        body: _loadingSerie ?
        Container(
          height: MediaQuery.of(context).size.height / 5,
          alignment: Alignment.center,
          color: Color(0xff6200ff),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(child: CircularProgressIndicator(color: Colors.white,))
            ],
          ),
        )
            : Column(
          children: [
            // Container que muestra los detalles de la serie
            Container(
              height: MediaQuery.of(context).size.height / 5,
              alignment: Alignment.center,
              color: Color(0xff6200ff),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Aquí navegas a la pantalla CompetitionDetailPage con el ID de la competición
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompetitionDetailPage(id: _serieData.competitionID),
                        ),
                      );
                    },
                    child: Text(
                      _serieData.competitionName,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white,fontFamily: 'SequelSans', fontSize: 10.0),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Primer equipo
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Círculo y texto del primer equipo
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeamDetailPage(tricode: _serieData.equipo1),
                                ),
                              );
                            },
                            child: Container(
                              width: 65.0,
                              height: 65.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: Color(0xff2d0079), // El borde rojo
                                  width: 2.0, // El grosor del borde
                                ),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 45.0,
                                  height: 45.0,
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/${_serieData.equipo1.toLowerCase()}.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Texto de equipo1 debajo del círculo
                          GestureDetector(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TeamDetailPage(tricode: _serieData.equipo1),
                                  ),
                                );
                              },
                              child: Text(
                                _serieData.equipo1,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontFamily: 'Sequel100'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Texto del medio
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Texto central
                          Text(
                            _serieData.en_directo
                                ? "${_serieData.equipo1Count} - ${_serieData.equipo2Count} "
                                : _serieData.jugado
                                ? " ${_serieData.equipo1Count} - ${_serieData.equipo2Count} "
                                : " ${_serieData.hora.hour}:${_serieData.hora.minute.toString().padLeft(2, '0')} ",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontFamily: 'Sequel100', fontSize: 30.0),
                          ),
    // Nuevo texto para mostrar la hora
                          Text(
                            "${_serieData.hora.day.toString()}/${_serieData.hora.month.toString()}",
                            style: TextStyle(color: Colors.white, fontFamily: 'SequelSans', fontSize: 12.0),
                          ),
                          SizedBox(
                            height: 25,),
                        ],
                      ),
                      // Segundo equipo
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Círculo y texto del segundo equipo
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeamDetailPage(tricode: _serieData.equipo2),
                                ),
                              );
                            },
                            child: Container(
                              width: 65.0,
                              height: 65.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: Color(0xff2d0079), // El borde rojo
                                  width: 2.0, // El grosor del borde
                                ),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 45.0,
                                  height: 45.0,
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/${_serieData.equipo2.toLowerCase()}.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Texto de equipo2 debajo del círculo
                          GestureDetector(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TeamDetailPage(tricode: _serieData.equipo2),
                                  ),
                                );
                              },
                              child: Text(
                                _serieData.equipo2,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontFamily: 'Sequel100'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                ],
              ),
            ),
            // Sección para las pantallas desplazables
            Expanded(
              child: DefaultTabController(
                length: 3,
                initialIndex : _serieData.jugado || _serieData.en_directo ? 0 : 1, // Cambio de índice inicial según el valor de _serieData.jugado
                child: Scaffold(
                  backgroundColor: Colors.white,
                  appBar: AppBar(
                    toolbarHeight: 3,
                    automaticallyImplyLeading: false,
                    backgroundColor: Color(0xff6200ff),
                    bottom: TabBar(
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      labelStyle: TextStyle(fontSize: 16.0,fontFamily: 'SequelSans'),
                      unselectedLabelColor: Color(0xff2d0079),
                      isScrollable: false,
                      tabs: [
                        Tab(text: 'Partidos'),
                        Tab(text: 'Previa'),
                        Tab(text: 'Clasificación'),
                      ],
                    ),
                  ),
                  body: TabBarView(
                    children: [
                      // Pestaña "Partidos" con los IDs de los partidos
                      _loadingPartidos
                          ? Center(child: CircularProgressIndicator())
                          : _partidoIds.isEmpty
                          ? Center(
                        child: Text('No hay partidos',style: TextStyle(fontSize: 18.0,fontFamily: "SequelSans",color: Color(0xff6200ff))),
                      )
                          : ListView.builder(
                        itemCount: _partidoIds.length,
                        itemBuilder: (context, index) {
                          final partido = _partidoIds[index];

                          return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 7.0), // Ajusta los padding según sea necesario
                              title: ElevatedButton(
                                onPressed: () {
                                  // Navegar a la pantalla de detalle de la serie con los datos de la serie seleccionada
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PartidoDetailPage(
                                        id: partido.id,
                                        competition_id: _serieData.competitionID,
                                        serie_id: _serieData.id,
                                        equipo1: partido.ladoAzul,
                                        equipo2: partido.ladoRojo,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(

                                  textStyle: TextStyle(fontSize: 17.0, fontFamily: "Sequel100"),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  maximumSize: Size(100, 75), // Ajusta según sea necesario
                                  backgroundColor: partido.en_directo ? Color(0xff6200ff) : Colors.white,
                                  foregroundColor: partido.en_directo ? Color(0xff6200ff) : Colors.white,
                                  elevation: 0.1,
                                  side: BorderSide(width: 1.7, color: Color(0xff6200ff)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Imagen pequeña
                                          // Texto de la competencia
                                          Text(
                                            "Partido ${partido.id[1]}",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: "SequelSans",
                                              fontSize: 10.0, // Tamaño de fuente más pequeño
                                              color: partido.en_directo ? Colors.white : Color(0xff6200ff),
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
                                            partido.ladoAzul,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: _serieData.en_directo ? Colors.white : Color(0xff6200ff) ,

                                            ),
                                          ),
                                        ),
                                        // Imagen pequeña
                                        Image.asset(
                                            _serieData.en_directo ? 'assets/${partido.ladoAzul.toLowerCase()}2.png' : 'assets/${partido.ladoAzul.toLowerCase()}.png',
                                            width: 40,
                                            height: 40
                                        ),
                                        // Espaciado entre la imagen y el texto central
                                        // Contenedor con un ancho fijo para el texto central
                                        SizedBox(
                                          width: 120, // Ancho fijo para el texto central, ajusta según sea necesario
                                          child: Text(
                                            partido.en_directo ? '0 - 0'
                                                : partido.ganador == partido.ladoAzul
                                                ? '1 - 0'
                                                : '0 - 1',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 30,
                                              color: _serieData.en_directo ? Colors.white : Color(0xff6200ff),
                                            ),
                                          ),
                                        ),
                                        // Espaciado entre el texto central y la segunda imagen
                                        // Imagen pequeña
                                        Image.asset(
                                            _serieData.en_directo ? 'assets/${partido.ladoRojo.toLowerCase()}2.png' : 'assets/${partido.ladoRojo.toLowerCase()}.png',
                                            width: 40,
                                            height: 40
                                        ),
                                        // Contenedor con un ancho fijo para el texto del lado derecho
                                        SizedBox(
                                          width: 65, // Ajusta según sea necesario
                                          child: Text(
                                            partido.ladoRojo,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: _serieData.en_directo ? Colors.white : Color(0xff6200ff),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          );
                        },
                      ),
                      Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, // Alineación vertical al centro
                            crossAxisAlignment: CrossAxisAlignment.center, // Alineación horizontal al centro
                            children: [
                              // Línea de texto que muestra el número de partidos ganados por cada equipo
                              Text('Racha',style: TextStyle(fontSize: 30.0,fontFamily: "Sequel100",color: Color(0xff6200ff)),),
                              _buildUltimosPartidos(),
                              // Espacio entre los widgets de texto
                              SizedBox(height: 10),
                              Text('Face to Face',style: TextStyle(fontSize: 30.0,fontFamily: "Sequel100",color: Color(0xff6200ff))),
                              _partidosPrevios.isEmpty?SizedBox(height: 0)
                              :Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 7.0),
                                child: Row(
                                  children: [
                                    // Rectángulo rojo para el primer equipo
                                    Expanded(
                                      flex: _ganado1,
                                      child: Container(
                                        color: Color(0xff6200ff),
                                        height: 100.0, // Ajusta la altura según sea necesario
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                          child:Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start, // Alinea a la izquierda
                                          children: [
                                            Text(_serieData.equipo1,style: TextStyle(fontSize: 17.0,fontFamily: "SequelSans",color: Colors.white)),
                                            Text('$_ganado1', style: TextStyle(fontSize: 30.0,fontFamily: "Sequel100",color: Colors.white)), // Mostramos el valor de _ganado1
                                            Text('${(_ganado1 / (_ganado1 + _ganado2) * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 17.0,fontFamily: "SequelSans",color: Colors.white)), // Calculamos y mostramos el porcentaje
                                          ],
                                        ),
                                        ),
                                      ),
                                    ),
                                    // Rectángulo azul para el segundo equipo con borde interior
                                    Expanded(
                                      flex: _ganado2,
                                      child: Container(
                                        height: 100.0, // Ajusta la altura según sea necesario
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            color: Color(0xff6200ff), // Color del borde
                                            width: 3.0, // Grosor del borde
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 8.0,left: 8.0),
                                          child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end, // Alinea a la derecha
                                          children: [
                                            Text(_serieData.equipo2,style: TextStyle(fontSize: 17.0,fontFamily: "SequelSans",color:Color(0xff6200ff))),
                                            Text('$_ganado2',style: TextStyle(fontSize: 30.0,fontFamily: "Sequel100",color: Color(0xff6200ff))), // Mostramos el valor de _ganado2
                                            Text('${(_ganado2 / (_ganado1 + _ganado2) * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 17.0,fontFamily: "SequelSans",color: Color(0xff6200ff))), // Calculamos y mostramos el porcentaje
                                          ],
                                        ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ) ,
                              // Espacio entre el texto y la lista de partidos
                              SizedBox(height: 10),
                              _loadingPartidos2
                                  ? CircularProgressIndicator()
                                  : _partidosPrevios.isEmpty
                                  ? Text('No hay partidos previos entre ${_serieData.equipo1} y ${_serieData.equipo2}',style: TextStyle(fontSize: 18.0,fontFamily: "SequelSans",color: Color(0xff6200ff)),)
                                  : ListView.builder(
                                physics: NeverScrollableScrollPhysics(), // La lista no será desplazable
                                shrinkWrap: true, // Para que la lista tome solo el espacio necesario
                                itemCount: _partidosPrevios.length,
                                itemBuilder: (context, index) {
                                  SerieData serie = _partidosPrevios[index];
                                  return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 7.0), // Ajusta los padding según sea necesario
                                      title: ElevatedButton(
                                        onPressed: () {
                                          // Navegar a la pantalla de detalle de la serie con los datos de la serie seleccionada
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SerieDetailScreen(
                                                id: serie.id,
                                                competition_id: serie.competitionID,
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
                                          backgroundColor: serie.en_directo ? Color(0xff6200ff) : Colors.white,
                                          foregroundColor: serie.en_directo ? Color(0xff6200ff) : Colors.white,
                                          elevation: 0.1,
                                          side: BorderSide(width: 1.7, color: Color(0xff6200ff)),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [

                                            // Row para la parte superior del botón
                                            // Agrupación de la imagen y el texto central
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                // Contenedor con un ancho fijo para el texto del lado izquierdo
                                                SizedBox(
                                                  width: 65, // Ajusta según sea necesario
                                                  child: Text(
                                                    serie.equipo1,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: serie.en_directo ? Colors.white : Color(0xff6200ff) ,

                                                    ),
                                                  ),
                                                ),
                                                // Imagen pequeña
                                                Image.asset(
                                                    serie.en_directo ? 'assets/${serie.equipo1.toLowerCase()}2.png' : 'assets/${serie.equipo1.toLowerCase()}.png',
                                                    width: 40,
                                                    height: 40
                                                ),
                                                // Espaciado entre la imagen y el texto central
                                                // Contenedor con un ancho fijo para el texto central
                                                SizedBox(
                                                  width: 120, // Ancho fijo para el texto central, ajusta según sea necesario
                                                  child: Text(
                                                    serie.en_directo ? '${serie.equipo1Count} - ${serie.equipo2Count}' :
                                                    serie.jugado ? '${serie.equipo1Count} - ${serie.equipo2Count}' : '${serie.hora.hour}:${serie.hora.minute.toString().padLeft(2, '0')}',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: serie.en_directo ? 30 : 24,
                                                      color: serie.en_directo ? Colors.white : Color(0xff6200ff),
                                                    ),
                                                  ),
                                                ),
                                                // Espaciado entre el texto central y la segunda imagen
                                                // Imagen pequeña
                                                Image.asset(
                                                    serie.en_directo ? 'assets/${serie.equipo2.toLowerCase()}2.png' : 'assets/${serie.equipo2.toLowerCase()}.png',
                                                    width: 40,
                                                    height: 40
                                                ),
                                                // Contenedor con un ancho fijo para el texto del lado derecho
                                                SizedBox(
                                                  width: 65, // Ajusta según sea necesario
                                                  child: Text(
                                                    serie.equipo2,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: serie.en_directo ? Colors.white : Color(0xff6200ff),
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
                                                    serie.en_directo ? 'assets/lec2.png' : 'assets/lec.png',
                                                    width: 15, // Ajusta el ancho según sea necesario
                                                    height: 15, // Ajusta el alto según sea necesario
                                                  ),
                                                  // Texto de la competencia
                                                  Text(
                                                    serie.competitionName,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontFamily: "SequelSans",
                                                      fontSize: 8.0, // Tamaño de fuente más pequeño
                                                      color: serie.en_directo ? Colors.white : Color(0xff6200ff),
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
                              ),
                              // Espacio entre la lista de partidos y el último widget de texto
                              SizedBox(height: 10),
                              // Widget para mostrar los últimos 5 partidos de cada equipo
                              Text('Plantillas',style: TextStyle(fontSize: 30.0,fontFamily: "Sequel100",color: Color(0xff6200ff))),
                              _buildComparacionPlantillas(),
                            ],
                          ),
                        ),
                      ),

                      Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, // Alineación vertical al centro
                            crossAxisAlignment: CrossAxisAlignment.center, // Alineación horizontal al centro
                            children: [
                              if (_serieData.id.startsWith('g'))
                                DropdownButton<String>(
                                  style: TextStyle(
                                      fontFamily: "SequelSans", // Tamaño de fuente más pequeño
                                      color: Color(0xff6200ff), fontSize: 17
                                  ),
                                  value: selectedClasificacion,
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: 'lr',
                                      child: Text('Fase Regular'),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'gr',
                                      child: Text('Grupos'),
                                    ),
                                  ],
                                  onChanged: (newValue) {
                                    setState(() {
                                      selectedClasificacion = newValue!;
                                    });
                                  },
                                )
                              else if (_serieData.id.startsWith('p'))
                                DropdownButtonHideUnderline(
                                  child:DropdownButton<String>(
                                    style: TextStyle(
                                      fontFamily: "SequelSans", // Tamaño de fuente más pequeño
                                      color: Color(0xff6200ff), fontSize: 17
                                    ),
                                    iconEnabledColor: Color(0xff6200ff),
                                    value: selectedClasificacion,
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: 'lr',
                                        child: Text('Fase Regular'),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'gr',
                                        child: Text('Grupos'),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'pl',
                                        child: Text('Playoffs'),
                                      ),
                                    ],
                                    onChanged: (newValue) {
                                      setState(() {
                                        selectedClasificacion = newValue!;
                                      });
                                    },
                                  ),
                                ),
                               // Espacio entre el DropdownButton y el widget de clasificación
                              selectedClasificacion == 'lr'
                                  ? _buildClasificacion1()
                                  : selectedClasificacion == 'gr'
                                  ? _buildClasificacion2()
                                  : _buildClasificacion3(),
                            ],
                          ),
                        ),
                      )

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}



