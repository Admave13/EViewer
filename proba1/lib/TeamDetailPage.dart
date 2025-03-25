import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proba1/CompetitionDetailPage.dart';
import 'SerieDetailPage.dart';
import 'PlayerDetailPage.dart';
import 'package:url_launcher/url_launcher.dart';


class TeamData{
  final String id;
  final String nombre;
  final String last_comp;
  final String twitter;
  final String instagram;
  TeamData({
    required this.id,
    required this.nombre,
    required this.last_comp,
    required this.twitter,
    required this.instagram
  });
}

class SerieData {
  final String equipo1;
  final String equipo2;
  final bool jugado;
  final DateTime hora;
  late int equipo1Count;
  late int equipo2Count;
  late String id;
  late String ganador;
  final String grupo;
  final String competitionID;
  final String competitionName;
  SerieData({
    required this.equipo1,
    required this.equipo2,
    required this.jugado,
    required this.hora,
    required this.id,
    required this.ganador,
    required this.equipo1Count,
    required this.equipo2Count,
    required this.competitionID,
    this.grupo = 'no', // Valor predeterminado 'no' si el grupo es nulo
    this.competitionName = 'no',
  });
}

class TeamDetailPage extends StatefulWidget {
  final String tricode;

  TeamDetailPage({required this.tricode});

  @override
  _TeamDetailPageState createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage> {
  late bool _loadingPlayer = true;
  String selectedGroup = 'A';
  late List<SerieData> grupoA=[]; // Lista para el grupo A
  late List<SerieData> grupoB=[]; // Lista para el grupo B
  late List<SerieData> listaAMostrar=grupoA;
  String selectedClasificacion="lr";
  int fase=1; //cambiar a la situacion actual segun la competicion
  final hora = DateTime(2023, 6, 26);
  late TeamData _TeamData =TeamData(
    id: "Null",
    nombre: "Null",
    last_comp: "Null",
      instagram: "Null",
      twitter: "Null"
  );

  @override
  void initState() {
    super.initState();
    _fetchTeamData();
  }

  void _fetchTeamData() async {
    final playerSnapshot = await FirebaseFirestore.instance
        .collection('teams_info')
        .doc(widget.tricode)
        .get();

    final playerData = playerSnapshot.data() as Map<String, dynamic>;
    setState(() {
      _TeamData = TeamData(
        id: widget.tricode,
        nombre: playerData['nombre'],
        last_comp: playerData["last_comp"],
          instagram: "Null",
          twitter: "Null"
      );
    });
    print("100");
    final compSnapshot = await FirebaseFirestore.instance
        .collection('competition')
        .doc(_TeamData.last_comp)
        .get();

    final compData = compSnapshot.data() as Map<String, dynamic>;
    print(compData["fase"]);
    setState(() {
      fase = compData["fase"];
    });


    print("acrio");
    _loadingPlayer = false;
    _fetchClasificacionData();

  }

  Future<List> getSeries() async {
    final db = FirebaseFirestore.instance;
    String equipo=_TeamData.id;
    final filterEquipo1 = FieldPath(['equipo1']);
    final filterEquipo2 = FieldPath(['equipo2']);

    final seriesEquipo1 = await db
        .collectionGroup('series')
        .where(filterEquipo1, isEqualTo: equipo)
        .where('hora', isGreaterThan: Timestamp.fromDate(hora))
        .orderBy('hora')
        .limit(1)
        .get()
        .then((value) => value.docs);

    final seriesEquipo2 = await db
        .collectionGroup('series')
        .where(filterEquipo2, isEqualTo: equipo)
        .where('hora', isGreaterThan: Timestamp.fromDate(hora))
        .orderBy('hora')
        .limit(1)
        .get()
        .then((value) => value.docs);

    final serieMasCercana = (seriesEquipo1.isNotEmpty && seriesEquipo2.isNotEmpty)
        ? (seriesEquipo1[0].data()['hora'] as Timestamp).compareTo(seriesEquipo2[0].data()['hora'] as Timestamp) < 0
        ? seriesEquipo1[0]
        : seriesEquipo2[0]
        : (seriesEquipo1.isNotEmpty ? seriesEquipo1[0] : (seriesEquipo2.isNotEmpty ? seriesEquipo2[0] : null));

    final competitionDoc = await serieMasCercana!.reference.parent.parent?.get();
    List sr = [
      serieMasCercana!.data()['equipo1'],
      serieMasCercana.data()['equipo2'],
      serieMasCercana.id,
      competitionDoc!.id,
      competitionDoc!.data()!["nombre"],
      6,
      serieMasCercana.data()['en_directo'] ?? false,
      (serieMasCercana.data()['hora'] as Timestamp).toDate(),
      serieMasCercana!.data()['equipo1Count'],
      serieMasCercana.data()['equipo2Count']
    ];

    return (sr);
  }

  Future<List> getSeries2() async {
    final db = FirebaseFirestore.instance;
    String equipo = _TeamData.id;
    final filterEquipo1 = FieldPath(['equipo1']);
    final filterEquipo2 = FieldPath(['equipo2']);

    final seriesEquipo1Last = await db
        .collectionGroup('series')
        .where(filterEquipo1, isEqualTo: equipo)
        .where('hora', isLessThan: Timestamp.fromDate(hora))
        .orderBy('hora', descending: true)
        .limit(1)
        .get()
        .then((value) => value.docs);

    final seriesEquipo2Last = await db
        .collectionGroup('series')
        .where(filterEquipo2, isEqualTo: equipo)
        .where('hora', isLessThan: Timestamp.fromDate(hora))
        .orderBy('hora', descending: true)
        .limit(1)
        .get()
        .then((value) => value.docs);

    final serieUltimaJugada = (seriesEquipo1Last.isNotEmpty && seriesEquipo2Last.isNotEmpty)
        ? (seriesEquipo1Last[0].data()['hora'] as Timestamp).compareTo(seriesEquipo2Last[0].data()['hora'] as Timestamp) > 0
        ? seriesEquipo1Last[0]
        : seriesEquipo2Last[0]
        : (seriesEquipo1Last.isNotEmpty ? seriesEquipo1Last[0] : (seriesEquipo2Last.isNotEmpty ? seriesEquipo2Last[0] : null));

    final competitionDocLast = await serieUltimaJugada?.reference.parent.parent?.get();

    List srLast = [
      serieUltimaJugada!.data()['equipo1'],
      serieUltimaJugada.data()['equipo2'],
      serieUltimaJugada.id,
      competitionDocLast!.id,
      competitionDocLast!.data()!["nombre"],
      6,
      serieUltimaJugada.data()['en_directo'] ?? false,
      (serieUltimaJugada.data()['hora'] as Timestamp).toDate(),
      serieUltimaJugada!.data()['equipo1Count'],
      serieUltimaJugada.data()['equipo2Count']
    ];

    return srLast;
  }


  Future<List<SerieData>> getMatchesForPlayer() async {
    List<SerieData> partidosList = [];
    print("toad");
    var playersQuery = await FirebaseFirestore.instance
        .collectionGroup('teams')
        .where('tricode', isEqualTo:_TeamData.id )
        .get();

    for (var playerDoc in playersQuery.docs) {
      var competitionId = playerDoc.reference.parent.parent!.id;
      final competitionDoc = await playerDoc.reference.parent.parent?.get();
      final competitionName = competitionDoc
          ?.data()?['nombre']; // Obtener el campo "nombre" de la competición
      var seriesQuery = await FirebaseFirestore.instance
          .collection('competition')
          .doc(competitionId)
          .collection('series')
          .where('equipo1', isEqualTo:_TeamData.id )
          .where('jugado', isEqualTo:true)
          .get();

      for (var x in seriesQuery.docs) {
        partidosList.add(SerieData(
          equipo1: x['equipo1'],
          equipo2: x['equipo2'],
          ganador: x['ganador'],
          jugado:x["jugado"],
          hora: (x['hora'] as Timestamp).toDate(),
          id: x.id,
          equipo1Count: int.parse(x['equipo1Count']),
          equipo2Count: int.parse(x['equipo2Count']),
          competitionID: competitionId,
            competitionName:competitionName
        ));
      }
      seriesQuery = await FirebaseFirestore.instance
          .collection('competition')
          .doc(competitionId)
          .collection('series')
          .where('equipo2', isEqualTo:_TeamData.id )
          .where('jugado', isEqualTo:true)
          .get();

      for (var x in seriesQuery.docs) {
        partidosList.add(SerieData(
          equipo1: x['equipo1'],
          equipo2: x['equipo2'],
          ganador: x['ganador'],
          jugado:x["jugado"],
          hora: (x['hora'] as Timestamp).toDate(),
          id: x.id,
          equipo1Count: int.parse(x['equipo1Count']),
          equipo2Count: int.parse(x['equipo2Count']),
            competitionID: competitionId,
            competitionName:competitionName
        ));
      }
      }

    partidosList.sort((a, b) => b.hora.compareTo(a.hora));
    return partidosList;
  }

  Future<List<String>> getTeammates() async {
    List<String> teammates = [];

    QuerySnapshot jugadores = await FirebaseFirestore.instance
        .collection('competition')
        .doc(_TeamData.last_comp)
        .collection('teams')
        .doc(_TeamData.id)
        .collection('players')
        .get();

    List<String> topLanes = [];
    List<String> jungle = [];
    List<String> midLanes = [];
    List<String> bottomLanes = [];
    List<String> support = [];

    jugadores.docs.forEach((jugador) {
      String posicion = jugador['posicion']; // Suponiendo que 'posicion' es un campo en tu documento Firestore
      String id = jugador.id;

      switch (posicion) {
        case 'TOP':
          topLanes.add(id);
          break;
        case 'JNG':
          jungle.add(id);
          break;
        case 'MID':
          midLanes.add(id);
          break;
        case 'BOT':
          bottomLanes.add(id);
          break;
        case 'SUP':
          support.add(id);
          break;
        default:
          break;
      }
    });

    // Agregar los compañeros de equipo ordenados por posición
    teammates.addAll(topLanes);
    teammates.addAll(jungle);
    teammates.addAll(midLanes);
    teammates.addAll(bottomLanes);
    teammates.addAll(support);

    return teammates;
  }


  Future<Map<String, List<dynamic>>> getPlayerTrajectory() async {
    Map<String, List<dynamic>> competitionsPlantilla = {};

    try {
      QuerySnapshot<Map<String, dynamic>> playersSnapshot =
      await FirebaseFirestore.instance
          .collectionGroup('teams')
          .where('tricode', isEqualTo: _TeamData.id)
          .get();

      await Future.forEach(playersSnapshot.docs, (playerDoc) async {
        String competitionId = playerDoc.reference.parent.parent!.id;
        final competitionDoc = await playerDoc.reference.parent.parent!.get();
        final competitionFase = competitionDoc.data()?['fase'];
        final competitionName = competitionDoc.data()?['nombre'];

        if (competitionFase == 4) {
          List<Map<String, dynamic>> teammatesData = [];
          List<String> topLanes = [];
          List<String> jungle = [];
          List<String> midLanes = [];
          List<String> bottomLanes = [];
          List<String> support = [];

          QuerySnapshot<Map<String, dynamic>> jugadoresSnapshot =
          await FirebaseFirestore.instance
              .collection('competition')
              .doc(competitionId)
              .collection('teams')
              .doc(_TeamData.id)
              .collection('players')
              .get();

          jugadoresSnapshot.docs.forEach((jugador) {
            dynamic position = jugador.data()["posicion"] ?? "Unknown";
            String id = jugador.id;

            switch (position) {
              case 'TOP':
                topLanes.add(id);
                break;
              case 'JNG':
                jungle.add(id);
                break;
              case 'MID':
                midLanes.add(id);
                break;
              case 'BOT':
                bottomLanes.add(id);
                break;
              case 'SUP':
                support.add(id);
                break;
              default:
                break;
            }
          });

          // Obtener la posición del jugador
          dynamic position_LEC = playerDoc.data()["position_final"] ?? "Unknown";

          // Agregar los compañeros de equipo ordenados por posición
          teammatesData.addAll(topLanes.map((id) => {'teammate': id, 'position': 'TOP'}).toList());
          teammatesData.addAll(jungle.map((id) => {'teammate': id, 'position': 'JNG'}).toList());
          teammatesData.addAll(midLanes.map((id) => {'teammate': id, 'position': 'MID'}).toList());
          teammatesData.addAll(bottomLanes.map((id) => {'teammate': id, 'position': 'BOT'}).toList());
          teammatesData.addAll(support.map((id) => {'teammate': id, 'position': 'SUP'}).toList());

          // Si la competición no está en el diccionario, agregarla
          if (!competitionsPlantilla.containsKey(competitionName)) {
            competitionsPlantilla[competitionName] = [];
          }

          // Agregar la lista de compañeros de equipo y la posición del jugador al diccionario
          competitionsPlantilla[competitionName]!.add({
            'teammatesData': teammatesData,
            'position_LEC': position_LEC,
          });
        }
      });
    } catch (e) {
      print("Error: $e");
      // Manejar el error según sea necesario
    }
    return competitionsPlantilla;
  }


  Widget _buildClasificacion12() {
    return FutureBuilder<List<List<dynamic>>>(
      future: _getClasificacionData1(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error al cargar los datos');
        } else {
          List<List<dynamic>> clasificacion = snapshot.data!;
          return DataTable(
            columns: [
              DataColumn(label: Text('Equipo')),
              DataColumn(label: Text('Victorias')),
              DataColumn(label: Text('Derrotas')),
            ],
            rows: clasificacion.map((teamData) {
              return DataRow(cells: [
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
                    child: Text(teamData[0]),
                  ),
                ),
                DataCell(Text(teamData[1].toString())),
                DataCell(Text(teamData[2].toString())),
              ]);
            }).toList(),
          );
        }
      },
    );
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
          .doc(_TeamData.last_comp)
          .collection('teams')
          .get();

      // Inicializa los diccionarios de victorias y derrotas con 0 para cada equipo
      Map<String, int> victorias = {};
      Map<String, int> derrotas = {};
      Map<String, int> posiciones = {}; // Mapa para almacenar las posiciones

      equiposSnapshot.docs.forEach((equipo) {
        victorias[equipo.id] = 0;
        derrotas[equipo.id] = 0;
        // Verifica si la posición está definida para este equipo
        if (equipo["position"] != "Null") {
          posiciones[equipo.id] = equipo["position"];
        }
      });

      // Consulta para obtener las series
      QuerySnapshot seriesSnapshot = await FirebaseFirestore.instance
          .collection('competition')
          .doc(_TeamData.last_comp)
          .collection('series')
          .where('hora', isLessThanOrEqualTo: hora)
          .get();

      // Procesa las series para calcular victorias y derrotas
      seriesSnapshot.docs.forEach((x) {
        Map<String, dynamic> data = x.data() as Map<String, dynamic>;
        String ganador = data["ganador"];
        String equipo1 = data["equipo1"];
        String equipo2 = data["equipo2"];
        // Filtrar partidas cuyo ID empiece por 's'
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

      // Ordena los equipos según el número de victorias o la posición si está definida
      List<MapEntry<String, int>> sortedTeams;
      if (posiciones.isNotEmpty) {
        // Ordena por posición si está definida
        sortedTeams = posiciones.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
      } else {
        // Si no hay posiciones definidas, ordena por victorias
        sortedTeams = victorias.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
      }

      // Crea la lista de listas en el formato deseado
      clasificacion = sortedTeams.map((entry) {
        return [entry.key, victorias[entry.key] ?? 0, derrotas[entry.key] ?? 0];
      }).toList();

      return clasificacion;
    } catch (error) {
      print(error);
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
                  backgroundColor: selectedGroup == 'A' ? Colors.blue : null, // Color de fondo si es el grupo activo
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: TextTheme(button: TextStyle(color: selectedGroup == 'A' ? Colors.white : null)), // Color del texto si es el grupo activo
                  ),
                  child: Text('Grupo A'),
                ),
              ),
              SizedBox(width: 10), // Añadir espacio entre los botones
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedGroup = 'B';
                    listaAMostrar = grupoB;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedGroup == 'B' ? Colors.blue : null, // Color de fondo si es el grupo activo
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: TextTheme(button: TextStyle(color: selectedGroup == 'B' ? Colors.white : null)), // Color del texto si es el grupo activo
                  ),
                  child: Text('Grupo B'),
                ),
              ),
            ],
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('Ronda 1', style: TextStyle(fontWeight: FontWeight.bold)), // Etiqueta "R1"
                      SizedBox(height: 5), // Espacio entre la etiqueta y la lista
                      _buildColumnForRTypeMatches('r1'), // Columna para los partidos que contienen "r1"
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Ronda 2', style: TextStyle(fontWeight: FontWeight.bold)), // Etiqueta "R2"
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
      if (match.hora.isAfter(hora)) {
        // Si el partido aún no se ha jugado, mostrar "TBD - TBD"
        return ListTile(
          title: Text('${match.equipo1} - ${match.equipo2}'),
          onTap: () {
            // Navegar a la pantalla de detalle de la serie con los datos de la serie seleccionada
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SerieDetailScreen(
                  id: match.id,
                  competition_id: _TeamData.last_comp,
                ),
              ),
            );
          },
          //hacer que vaya
        );
      } else if  (match.hora == (hora)){
        return ListTile(
          title: Text("${match.equipo1} ${match.equipo1Count} - ${match.equipo2Count} ${match.equipo2}"),
          //hacer que vaya
        );
      } else {
        // Si el partido ya se ha jugado, mostrar los equipos y el resultado
        return ListTile(
          title: Text("${match.equipo1} ${match.equipo1Count} - ${match.equipo2Count} ${match.equipo2}"),
          onTap: () {
            // Navegar a la pantalla de detalle de la serie con los datos de la serie seleccionada
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SerieDetailScreen(
                  id: match.id,
                  competition_id: _TeamData.last_comp,
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
          .doc(_TeamData.last_comp)
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

        // Filtrar partidas cuyo ID empiece por 'g'
        if (x.id.startsWith('g')) {
          print(grupo);
          // Actualiza el diccionario de victorias y derrotas

          SerieData serie = SerieData(
              competitionID: _TeamData.last_comp,
              equipo1: equipo1,
              equipo2: equipo2,
              jugado: data["jugado"],
              hora: data["hora"].toDate(),
              id: x.id,
              ganador: ganador,
              equipo1Count: equipo1Count,
              equipo2Count: equipo2Count,
              grupo:grupo
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
                      Text('R1'), // Título para la columna R1
                      _buildColumnForPLypeMatches('pl1', grupo1), // Mostrar las partidas de R1
                    ],
                  ),
                ),
                SizedBox(width: 20), // Espacio entre las columnas
                Expanded(
                  child: Column(
                    children: [
                      Text('R2'), // Título para la columna R2
                      _buildColumnForPLypeMatches('pl2', grupo1), // Mostrar las partidas de R2
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('R3'), // Título para la columna R3
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
      if (match.hora.isAfter(hora)) {
        // Si el partido aún no se ha jugado, mostrar "TBD - TBD"
        return ListTile(
          title: Text('${match.equipo1} - ${match.equipo2}'),
          onTap: () {
            // Navegar a la pantalla de detalle de la serie con los datos de la serie seleccionada
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SerieDetailScreen(
                  id: match.id,
                  competition_id: _TeamData.last_comp,
                ),
              ),
            );
          },
          //hacer que vaya
        );
      } else if  (match.hora == (hora)){
        return ListTile(
          title: Text("${match.equipo1} ${match.equipo1Count} - ${match.equipo2Count} ${match.equipo2}"),
          //hacer que vaya
        );
      } else {
        // Si el partido ya se ha jugado, mostrar los equipos y el resultado
        return ListTile(
          title: Text("${match.equipo1} ${match.equipo1Count} - ${match.equipo2Count} ${match.equipo2}"),
          onTap: () {
            // Navegar a la pantalla de detalle de la serie con los datos de la serie seleccionada
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SerieDetailScreen(
                  id: match.id,
                  competition_id: _TeamData.last_comp,
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
          .doc(_TeamData.last_comp)
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

        // Filtrar partidas cuyo ID empiece por 'g'
        if (x.id.startsWith('p')) {
          print(grupo);
          // Actualiza el diccionario de victorias y derrotas

          SerieData serie = SerieData(
            competitionID: _TeamData.last_comp,
              equipo1: equipo1,
              equipo2: equipo2,
              jugado: data["jugado"],
              hora: data["hora"].toDate(),
              id: x.id,
              ganador: ganador,
              equipo1Count: equipo1Count,
              equipo2Count: equipo2Count,
              grupo:grupo
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


  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff6200ff),
          title: _loadingPlayer ? Text(
            _TeamData.nombre,
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xff6200ff), fontFamily: 'Sequel100'),
          )
              :Text(
            _TeamData.nombre,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontFamily: 'Sequel100'),
          ),
        ),
        body: _loadingPlayer
            ? Container(
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
            Container(
              height: MediaQuery.of(context).size.height / 6.4,
              alignment: Alignment.center,
              color: Color(0xff6200ff),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 75.0,
                        height: 75.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Color(0xff2d0079),
                            width: 2.0,
                          ),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 55.0,
                            height: 55.0,
                            child: ClipOval(
                              child: Image.asset(
                                'assets/${_TeamData.id.toLowerCase()}.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -10.0, // Ajusta la posición horizontal del círculo pequeño
                        bottom: 0, // Ajusta la posición vertical del círculo pequeño
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CompetitionDetailPage(id: _TeamData.last_comp),
                              ),
                            );
                          },
                          child: Container(
                            width: 35.0,
                            height: 35.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: Color(0xff2d0079),
                                width: 1.0,
                              ),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 25.0,
                                height: 25.0,
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/leclogo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      ),
                    ],
                  ),
                   // Agrega un espacio entre los textos
                ],
              )

            ),
            Expanded(
              child: DefaultTabController(
                length: 5,
                child: Scaffold(
                  //backgroundColor: Colors.white,
                  appBar: AppBar(
                    toolbarHeight: 3,
                    automaticallyImplyLeading: false,
                    backgroundColor: Color(0xff6200ff),
                    bottom: TabBar(
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      labelStyle: TextStyle(fontSize: 16.0,fontFamily: 'SequelSans'),
                      unselectedLabelColor: Color(0xff2d0079),
                      isScrollable: true,
                      labelPadding:
                      EdgeInsets.symmetric(horizontal: 16.0),
                      tabs: [
                        Tab(text: 'Información'),
                        Tab(text: 'Series'),
                        Tab(text: 'Plantilla'),
                        Tab(text: 'Palmarés'),
                        Tab(text: 'Clasificación'),
                      ],
                    ),
                  ),
                  body: TabBarView(
                    children: [
                      Container(
                        child: Center(
                          child: Column(
                            children: <Widget>[
                              // Línea de texto para mostrar el resultado de la función
                              Text('Siguiente Serie',style: TextStyle(fontSize: 25.0,fontFamily: "Sequel100",color: Color(0xff6200ff))),
                            FutureBuilder<List>(
                              future: getSeries(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  // Mostrar un indicador de carga mientras los datos se están obteniendo
                                  return Center(child: CircularProgressIndicator());
                                }

                                if (snapshot.hasData) {
                                  final data = snapshot.data!;
                                  final equipo1 = data[0];
                                  final equipo2 = data[1];
                                  final serieId = data[2];
                                  final competitionId = data[3];
                                  final competitionName = data[4];
                                  final jornada = data[5]; // Asegúrate de que 'jornada' esté incluido en los datos que se obtienen
                                  final enDirecto = data[6]; // Asegúrate de que 'enDirecto' esté incluido en los datos que se obtienen
                                  final Shora = data[7]; // Asegúrate de que 'hora' esté incluido en los datos que se obtienen
                                  final equipo1Count = data[8]; // Asegúrate de que 'equipo1Count' esté incluido en los datos que se obtienen
                                  final equipo2Count = data[9]; // Asegúrate de que 'equipo2Count' esté incluido en los datos que se obtienen

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 7.0),
                                    title: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SerieDetailScreen(
                                              id: serieId,
                                              competition_id: competitionId,
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
                                        backgroundColor: enDirecto ? Color(0xff6200ff) : Colors.white,
                                        foregroundColor: enDirecto ? Colors.white : Color(0xff6200ff),
                                        elevation: 0.1,
                                        side: BorderSide(width: 1.7, color: Color(0xff6200ff)),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Jornada y competencia
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              // Texto e imagen de equipo 1
                                              SizedBox(
                                                width: 65, // Ajusta según sea necesario
                                                child: Text(
                                                  equipo1,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: enDirecto ? Colors.white : Color(0xff6200ff),
                                                  ),
                                                ),
                                              ),
                                              Image.asset(
                                                enDirecto ? 'assets/${equipo1.toLowerCase()}2.png' : 'assets/${equipo1.toLowerCase()}.png',
                                                width: 40,
                                                height: 40,
                                              ),
                                              // Texto central: resultado o hora
                                              SizedBox(
                                                width: 120,
                                                child: Text(
                                                  enDirecto ? '${equipo1Count} - ${equipo2Count}' :
                                                  '${Shora.hour}:${Shora.minute.toString().padLeft(2, '0')}',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: enDirecto ? 30 : 24,
                                                    color: enDirecto ? Colors.white : Color(0xff6200ff),
                                                  ),
                                                ),
                                              ),
                                              // Imagen y texto de equipo 2
                                              Image.asset(
                                                enDirecto ? 'assets/${equipo2.toLowerCase()}2.png' : 'assets/${equipo2.toLowerCase()}.png',
                                                width: 40,
                                                height: 40,
                                              ),
                                              SizedBox(
                                                width: 65, // Ajusta según sea necesario
                                                child: Text(
                                                  equipo2,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: enDirecto ? Colors.white : Color(0xff6200ff),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Información sobre la competencia
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 0),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  enDirecto ? 'assets/lec2.png' : 'assets/lec.png',
                                                  width: 15,
                                                  height: 15,
                                                ),
                                                Text(
                                                  competitionName,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontFamily: "SequelSans",
                                                    fontSize: 8.0,
                                                    color: enDirecto ? Colors.white : Color(0xff6200ff),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                // Mostrar un mensaje de error si no hay datos disponibles
                                return Center(child: Text('No se pudo obtener datos sobre el siguiente partido'));
                              },
                            ),
                            Text('Última Serie',style: TextStyle(fontSize: 25.0,fontFamily: "Sequel100",color: Color(0xff6200ff))),
                              FutureBuilder<List>(
                                future: getSeries2(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    // Mostrar un indicador de carga mientras los datos se están obteniendo
                                    return Center(child: CircularProgressIndicator());
                                  }

                                  if (snapshot.hasData) {
                                    final data = snapshot.data!;
                                    final equipo1 = data[0];
                                    final equipo2 = data[1];
                                    final serieId = data[2];
                                    final competitionId = data[3];
                                    final competitionName = data[4];
                                    final jornada = data[5]; // Asegúrate de que 'jornada' esté incluido en los datos que se obtienen
                                    final enDirecto = data[6]; // Asegúrate de que 'enDirecto' esté incluido en los datos que se obtienen
                                    final Shora = data[7]; // Asegúrate de que 'hora' esté incluido en los datos que se obtienen
                                    final equipo1Count = data[8]; // Asegúrate de que 'equipo1Count' esté incluido en los datos que se obtienen
                                    final equipo2Count = data[9]; // Asegúrate de que 'equipo2Count' esté incluido en los datos que se obtienen

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 7.0),
                                      title: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SerieDetailScreen(
                                                id: serieId,
                                                competition_id: competitionId,
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
                                          backgroundColor: enDirecto ? Color(0xff6200ff) : Colors.white,
                                          foregroundColor: enDirecto ? Colors.white : Color(0xff6200ff),
                                          elevation: 0.1,
                                          side: BorderSide(width: 1.7, color: Color(0xff6200ff)),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // Jornada y competencia
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                // Texto e imagen de equipo 1
                                                SizedBox(
                                                  width: 65, // Ajusta según sea necesario
                                                  child: Text(
                                                    equipo1,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: enDirecto ? Colors.white : Color(0xff6200ff),
                                                    ),
                                                  ),
                                                ),
                                                Image.asset(
                                                  enDirecto ? 'assets/${equipo1.toLowerCase()}2.png' : 'assets/${equipo1.toLowerCase()}.png',
                                                  width: 40,
                                                  height: 40,
                                                ),
                                                // Texto central: resultado o hora
                                                SizedBox(
                                                  width: 120,
                                                  child: Text(
                                                    '${equipo1Count} - ${equipo2Count}',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: enDirecto ? 30 : 24,
                                                      color: enDirecto ? Colors.white : Color(0xff6200ff),
                                                    ),
                                                  ),
                                                ),
                                                // Imagen y texto de equipo 2
                                                Image.asset(
                                                  enDirecto ? 'assets/${equipo2.toLowerCase()}2.png' : 'assets/${equipo2.toLowerCase()}.png',
                                                  width: 40,
                                                  height: 40,
                                                ),
                                                SizedBox(
                                                  width: 65, // Ajusta según sea necesario
                                                  child: Text(
                                                    equipo2,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: enDirecto ? Colors.white : Color(0xff6200ff),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Información sobre la competencia
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 0),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Image.asset(
                                                    enDirecto ? 'assets/lec2.png' : 'assets/lec.png',
                                                    width: 15,
                                                    height: 15,
                                                  ),
                                                  Text(
                                                    competitionName,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontFamily: "SequelSans",
                                                      fontSize: 8.0,
                                                      color: enDirecto ? Colors.white : Color(0xff6200ff),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  // Mostrar un mensaje de error si no hay datos disponibles
                                  return Center(child: Text('No se pudo obtener datos sobre el siguiente partido'));
                                },
                              ),
                              Text('Redes Sociales',style: TextStyle(fontSize: 25.0,fontFamily: "Sequel100",color: Color(0xff6200ff))),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_TeamData.twitter != "no") // Agrega esta condición
                                    GestureDetector(
                                      onTap: () {
                                        // Abre el enlace en el navegador cuando se toca la imagen
                                        launch('https://twitter.com/${_TeamData.twitter}');
                                      },
                                      child: Image.asset(
                                        'assets/logo_twitter.png', // Reemplaza con la ruta de tu imagen local
                                        width: 50.0,
                                        height: 50.0,
                                      ),
                                    ),
                                  SizedBox(width: 30,),
                                  if (_TeamData.instagram != "no") // Agrega esta condición
                                    GestureDetector(
                                      onTap: () {
                                        // Abre el enlace en el navegador cuando se toca la imagen
                                        launch('https://instagram.com/${_TeamData.instagram}');
                                      },
                                      child: Image.asset(
                                        'assets/logo_ig.png', // Reemplaza con la ruta de tu imagen local
                                        width: 50.0,
                                        height: 50.0,
                                      ),
                                    ),
                                ],
                              )

                              // Agrega más Text widgets según sea necesario para otros valores
                            ],
                          ),
                        ),
                      ),
                      Container(
                        child: Center(
                          child: FutureBuilder<List<SerieData>>(
                            future: getMatchesForPlayer(), // Reemplaza 'nombre del jugador' por el nombre real del jugador
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return CircularProgressIndicator(); // Muestra un indicador de carga mientras se carga la lista de partidos
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}'); // Muestra un mensaje de error si ocurrió un error
                              } else {
                                return ListView.builder(
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    var partido = snapshot.data![index];
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 7.0), // Ajusta los padding según sea necesario
                                      title: ElevatedButton(
                                        onPressed: () {
                                          // Navegar a la pantalla de detalle de la serie con los datos del partido seleccionado
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SerieDetailScreen(
                                                id: partido.id,
                                                competition_id: partido.competitionID,
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
                                          backgroundColor: Colors.white,
                                          foregroundColor: Color(0xff6200ff),
                                          elevation: 0.1,
                                          side: BorderSide(width: 1.7, color: Color(0xff6200ff)),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "${partido.hora.day}/${partido.hora.month}/${partido.hora.year}",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: "SequelSans",
                                                fontSize: 8.0,
                                                color: Color(0xff6200ff),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 65, // Ajusta según sea necesario
                                                  child: Text(
                                                    partido.equipo1,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Color(0xff6200ff),
                                                    ),
                                                  ),
                                                ),
                                                Image.asset(
                                                  'assets/${partido.equipo1.toLowerCase()}.png',
                                                  width: 40,
                                                  height: 40,
                                                ),
                                                SizedBox(
                                                  width: 120,
                                                  child: Text(
                                                    partido.jugado ? '${partido.equipo1Count} - ${partido.equipo2Count}' : '${partido.hora.hour}:${partido.hora.minute.toString().padLeft(2, '0')}',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize:24,
                                                      color:Color(0xff6200ff),
                                                    ),
                                                  ),
                                                ),
                                                Image.asset(
                                                  'assets/${partido.equipo2.toLowerCase()}.png',
                                                  width: 40,
                                                  height: 40,
                                                ),
                                                SizedBox(
                                                  width: 65,
                                                  child: Text(
                                                    partido.equipo2,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Color(0xff6200ff),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 0),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Image.asset(
                                                    'assets/lec.png',
                                                    width: 15,
                                                    height: 15,
                                                  ),
                                                  Text(
                                                    partido.competitionName,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontFamily: "SequelSans",
                                                      fontSize: 8.0,
                                                      color: Color(0xff6200ff),
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
                                );
                              }
                            },
                          ),
                        )
                      ), //done
                      Container(
                        child: FutureBuilder<List<String>>(
                          future: getTeammates(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            } else {
                              List<String> teammates = snapshot.data ?? [];
                              return GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3, // Especifica que haya 3 elementos por fila
                                  crossAxisSpacing: 10.0, // Ajusta el espacio entre elementos en el eje transversal (horizontal)
                                  mainAxisSpacing: 15.0, // Ajusta el espacio entre elementos en el eje longitudinal (vertical)
                                ),
                                itemCount: teammates.length,
                                itemBuilder: (context, index) {
                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('players_info')
                                        .doc(teammates[index])
                                        .get(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Center(child: CircularProgressIndicator());
                                      }

                                      if (snapshot.hasError) {
                                        return Center(child: Text('Error loading data'));
                                      }

                                      if (snapshot.hasData && snapshot.data!.exists) {
                                        final jugadorInfoDoc = snapshot.data!;
                                        final foto = jugadorInfoDoc['foto'] ?? 'null';

                                        return ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            textStyle: TextStyle(fontSize: 12.0, fontFamily: "Sequel100"),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12.0),
                                            ),
                                            maximumSize: Size(100, 90), // Ajusta según sea necesario
                                            backgroundColor: Colors.white,
                                            foregroundColor: Color(0xff6200ff),
                                            elevation: 0.1,
                                            padding: EdgeInsets.all(8),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => PlayerDetailPage(ign: teammates[index]),
                                              ),
                                            );
                                          },
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              if (foto != 'null')
                                          Container(
                                          width: 70.0,
                                          height: 70.0,
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
                                              width: 70.0,
                                              height: 70.0,
                                              child: ClipOval(
                                                  child: Image.network(
                                                    foto,
                                                    fit: BoxFit.cover,
                                                  )
                                              ),
                                            ),
                                          ),
                                        ),
                                              SizedBox(height: 8), // Espacio entre la imagen y el texto
                                              Text(teammates[index],
                                                style: TextStyle(fontSize: 10.0, fontFamily: "Sequel100"),), // Texto del compañero de equipo
                                            ],
                                          ),
                                        );
                                      } else {
                                        return Center(child: Text('No data available'));
                                      }
                                    },
                                  );
                                },
                              );



                            }
                          },
                        ),
                      ), //done
                      Container(
                        child: Center(
                          child: FutureBuilder<Map<String, List<dynamic>>>(
                            future: getPlayerTrajectory(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Text('No hay datos disponibles');
                              } else {
                                return ListView(
                                  children: snapshot.data!.entries.map((entry) {
                                    String key = entry.key; // El ID de la competición
                                    List<dynamic> competitions = entry.value; // La lista de datos de la competición

                                    // Crear un ValueNotifier para rastrear el estado de expansión del ExpansionTile
                                    ValueNotifier<bool> isExpanded = ValueNotifier(false);

                                    return Card(
                                      color: Colors.white,
                                      elevation: 0.0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(0.0),
                                        side: BorderSide(color: Color(0xff6200ff)),
                                      ),
                                      margin: EdgeInsets.all(8.0),
                                      child: ValueListenableBuilder<bool>(
                                        valueListenable: isExpanded,
                                        builder: (context, expanded, child) {
                                          return ExpansionTile(
                                            title: Row(
                                              children: [
                                                // Cambia la imagen según el estado de expansión
                                                Image.asset(
                                                  expanded ? 'assets/lec2.png' : 'assets/lec.png',
                                                  width: 30,
                                                  height: 30,
                                                ),
                                                Text(
                                                  '$key - ${competitions.first['position_LEC']}º',
                                                  style: TextStyle(
                                                    color: expanded ? Colors.white : Color(0xff6200ff),
                                                    fontFamily: "Sequel100",
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            textColor: Colors.white,
                                            collapsedTextColor: Colors.black,
                                            backgroundColor: Color(0xff6200ff),
                                            childrenPadding: EdgeInsets.all(8.0),
                                            onExpansionChanged: (isExpandedValue) {
                                              isExpanded.value = isExpandedValue;
                                            },
                                            children: competitions.expand((data) {
                                              List<Map<String, dynamic>> teammatesData = data['teammatesData'];
                                              dynamic position_LEC = data['position_LEC'];

                                              return teammatesData.map((teammateData) {
                                                String teammate = teammateData['teammate'];
                                                dynamic position = teammateData['position'];

                                                return FutureBuilder<DocumentSnapshot>(
                                                  future: FirebaseFirestore.instance
                                                      .collection('players_info')
                                                      .doc(teammate)
                                                      .get(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                                      return CircularProgressIndicator();
                                                    }

                                                    if (snapshot.hasError) {
                                                      return Text('Error loading data');
                                                    }

                                                    if (snapshot.hasData && snapshot.data!.exists) {
                                                      final jugadorInfoDoc = snapshot.data!;
                                                      final foto = jugadorInfoDoc['foto'] ?? 'null';

                                                      return ListTile(
                                                        title: Row(
                                                          children: [
                                                            Container(
                                                              width: 45.0,
                                                              height: 45.0,
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape.circle,
                                                                color: Colors.white,
                                                                border: Border.all(
                                                                  color: Color(0xff2d0079), // El borde rojo
                                                                  width: 2.0,
                                                                ),
                                                              ),
                                                              child: Center(
                                                                child: SizedBox(
                                                                  width: 45.0,
                                                                  height: 45.0,
                                                                  child: ClipOval(
                                                                    child: foto != 'null'
                                                                        ? Image.network(
                                                                      foto,
                                                                      fit: BoxFit.cover,
                                                                    )
                                                                        : Container(
                                                                      color: Colors.grey,
                                                                      child: Center(
                                                                        child: Icon(
                                                                          Icons.person,
                                                                          color: Colors.white,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(width: 8), // Espacio entre la foto y el texto
                                                            Text(
                                                              teammate,
                                                              style: TextStyle(color: Colors.white, fontFamily: "Sequel100"),
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              position,
                                                              style: TextStyle(color: Colors.white, fontFamily: "SequelSans"),
                                                            ),
                                                          ],
                                                        ),
                                                        onTap: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) => PlayerDetailPage(ign: teammate),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    } else {
                                                      return Text('No data available');
                                                    }
                                                  },
                                                );
                                              }).toList();
                                            }).toList(),
                                          );
                                        },
                                      ),
                                    );

                                  }).toList(),
                                );




                              }
                            },
                          ),


                        ),
                      ), //done
                      Container(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center, // Alineación vertical al centro
                                crossAxisAlignment: CrossAxisAlignment.center, // Alineación horizontal al centro
                                children: [
                                  if (fase==2)
                                    DropdownButton<String>(
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
                                  else if (fase>=3)
                                    DropdownButton<String>(
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
                                  selectedClasificacion == 'lr'
                                      ? _buildClasificacion1()
                                      : selectedClasificacion == 'gr'
                                      ? _buildClasificacion2()
                                      : _buildClasificacion3(),
                                ]
                            ),
                          ),
                        )
                      ), //done
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