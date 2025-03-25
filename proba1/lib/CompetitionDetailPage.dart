import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SerieDetailPage.dart';
import 'TeamDetailPage.dart';
import 'PlayerDetailPage.dart';

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
  SerieData({
    required this.equipo1,
    required this.equipo2,
    required this.jugado,
    required this.hora,
    required this.id,
    required this.ganador,
    required this.equipo1Count,
    required this.equipo2Count,
    this.grupo = 'no', // Valor predeterminado 'no' si el grupo es nulo
  });
}

class CompetitionData{
  final String id;
  final int fase;
  final String nombre;
  CompetitionData({
    required this.id,
    required this.fase,
    required this.nombre,
  });
}

class CompetitionDetailPage extends StatefulWidget {
  final String id;

  CompetitionDetailPage({required this.id});

  @override
  _CompetitionDetailPageState createState() => _CompetitionDetailPageState();
}

class _CompetitionDetailPageState extends State<CompetitionDetailPage> {
  //sustituir los widget.id por la classe competiciondata -> falta fetch competicion data
  Future<List<SerieData>>? _partidosPorDia;
  Future<Map<String, List<String>>>? _yearsAndSplitsFuture;
  late bool _loadingPlayer = true;
  String selectedGroup = 'A';
  late List<SerieData> grupoA=[]; // Lista para el grupo A
  late List<SerieData> grupoB=[]; // Lista para el grupo B
  late List<SerieData> listaAMostrar=grupoA;
  String selectedClasificacion="lr";
  final hora = DateTime(2023, 6, 26);



  late CompetitionData _competitionData =CompetitionData(
    id: "Null",
    fase: 0,
    nombre: "Null",
  );

  @override
  void initState() {
    super.initState();
    _fetchCompetitionData();
  }
  void _fetchCompetitionData() async {
    final playerSnapshot = await FirebaseFirestore.instance
        .collection('competition')
        .doc(widget.id)
        .get();

    final playerData = playerSnapshot.data() as Map<String, dynamic>;
    setState(() {
      _competitionData = CompetitionData(
          id: widget.id,
          nombre: playerData['nombre'],
          fase: playerData['fase'],
      );
    });
    if (_competitionData.fase==2){
      setState(() {
        selectedClasificacion = 'gr';
      });
    }
    else if (_competitionData.fase>=3){
      setState(() {
        selectedClasificacion = 'pl';
      });
    }
    print("acrio");
    _yearsAndSplitsFuture = fetchYearsAndSplits();
    _partidosPorDia=obtenerPartidosPorDia();
    _loadingPlayer = false;
    _fetchClasificacionData();
  }

  Future<Map<String, List<String>>> fetchYearsAndSplits() async {
    Map<String, List<String>> data = {'years': [], 'splits': []};
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance.collection('competition').get();
    snapshot.docs.forEach((doc) {
      String year = doc.id.split('_')[1];
      String split = doc.id.split('_')[2];
      if (!data['years']!.contains(year)) {
        data['years']!.add(year);
      }
      if (!data['splits']!.contains(split)) {
        data['splits']!.add(split);
      }
    });
    return data;
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
          .doc(widget.id)
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
          .doc(widget.id)
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
      if (match.hora.isAfter(hora)) {
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
                  competition_id: widget.id,
                ),
              ),
            );
          },
          //hacer que vaya
        );
      } else if  (match.hora == (hora)){
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
                  competition_id: widget.id,
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
          .doc(widget.id)
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
      if (match.hora.isAfter(hora)) {
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
                  competition_id: widget.id,
                ),
              ),
            );
          },
          //hacer que vaya
        );
      } else if  (match.hora == (hora)){
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
                  competition_id: widget.id,
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
          .doc(widget.id)
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
      //print(clasificacion);
      return clasificacion;
    } catch (error) {
      throw error;
    }
  }

  Future<List<String>> getTeammates() async {
    List<String> teammates = [];

    QuerySnapshot jugadoresRef = await FirebaseFirestore.instance
        .collection('competition')
        .doc(widget.id)
        .collection("teams")
        .get();

    for (QueryDocumentSnapshot jugadorRef in jugadoresRef.docs) {
              teammates.add(jugadorRef.id);

    }
    return teammates;
  }

  Future<List<SerieData>> obtenerPartidosPorDia() async {
    List<SerieData> partidosPorDia = [];


      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('competition')
          .doc(widget.id)
          .collection('series')
          .orderBy('hora')
          .get();

      querySnapshot.docs.forEach((x) {
        Map<String, dynamic> data = x.data() as Map<String, dynamic>;
        Timestamp fechaTimestamp = data['hora'];
        String equipo1 = data['equipo1'];
        String equipo2 = data['equipo2'];
        bool jugado = data['jugado'];
        String id = x.id;
        String grupo = data['grupo'] ?? 'no'; // Valor predeterminado 'no' si el grupo es nulo

        SerieData serie = SerieData(
          equipo1: equipo1,
          equipo2: equipo2,
          jugado: jugado,
          hora: fechaTimestamp.toDate(),
          id: id,
          ganador: data['ganador'],
          equipo1Count: int.parse(data['equipo1Count']),
          equipo2Count: int.parse(data['equipo2Count']),
          grupo: grupo,
        );

        partidosPorDia.add(serie);
      });

      print("partidos por dias:");
      //print(partidosPorDia);
      return partidosPorDia;

  }

  Widget _buildPartidosPorDiaWidget(String fecha, List<SerieData> partidos) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Partidos del día: $fecha',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: Column(
              children: partidos.map((partido) {
                return Card(
                  child: ListTile(
                    contentPadding: EdgeInsets.all(8.0),
                    title: Text(
                      partido.jugado
                          ? '${partido.equipo1} ${partido.equipo1Count} - ${partido.equipo2Count} ${partido.equipo2}'
                          : '${partido.equipo1} ${partido.hora.hour}:${partido.hora.minute.toString().padLeft(2, '0')} ${partido.equipo2}',
                      textAlign: TextAlign.center,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SerieDetailScreen(
                            id: partido.id,
                            competition_id: widget.id,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<SerieData>> obtenerPartidosPorDia2() async {
    List<SerieData> partidosPorDia = [];

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('competition')
        .doc(widget.id)
        .collection('series')
        .orderBy('hora')
        .get();

    querySnapshot.docs.forEach((x) {
      Map<String, dynamic> data = x.data() as Map<String, dynamic>;
      Timestamp fechaTimestamp = data['hora'];
      String equipo1 = data['equipo1'];
      String equipo2 = data['equipo2'];
      bool jugado = data['jugado'];
      String id = x.id;
      String grupo = data['grupo'] ?? 'no'; // Valor predeterminado 'no' si el grupo es nulo

      SerieData serie = SerieData(
        equipo1: equipo1,
        equipo2: equipo2,
        jugado: jugado,
        hora: fechaTimestamp.toDate(),
        id: id,
        ganador: data['ganador'],
        equipo1Count: int.parse(data['equipo1Count']),
        equipo2Count: int.parse(data['equipo2Count']),
        grupo: grupo,
      );

      partidosPorDia.add(serie);
    });

    return partidosPorDia;
  }


  Future<Map<String, List<List<dynamic>>>> stats()async{
    print("entrado");
    Map<String, Map<String, dynamic>> estad = {};

    final series = await FirebaseFirestore.instance
        .collection('competition')
        .doc(_competitionData.id)
        .collection("series")
        .where("jugado", isEqualTo: true)
        .get();

    for (final serie in series.docs) {
      final partidos = await FirebaseFirestore.instance
          .collection('competition')
          .doc(_competitionData.id)
          .collection("series")
          .doc(serie.id)
          .collection("partido")
          .get();

      for (final partido in partidos.docs) {
        final data = partido.data();
        final sp = await FirebaseFirestore.instance
            .collection('competition')
            .doc(_competitionData.id)
            .collection("series")
            .doc(serie.id)
            .collection("partido")
            .doc(partido.id)
            .collection("situacion_partida")
            .doc("spfinal")
            .get();

        final data2 = sp.data();
        final jugadoresAzul = List<String>.from(data['jugadores_azul'] ?? []);
        final champsAzul = List<String>.from(data['champs_azul'] ?? []);
        final jugadoresRojo = List<String>.from(data['jugadores_rojo'] ?? []);
        final champsRojo = List<String>.from(data['champs_rojo'] ?? []);
        final kdaAzul = List<String>.from(data2!['kda_azul'] ?? []);
        final kdaRojo = List<String>.from(data2['kda_rojo'] ?? []);
        final minionsAzul = List<String>.from(data2['minions_azul'] ?? []);
        final minionsRojo = List<String>.from(data2['minions_rojo'] ?? []);
        final minuto = int.parse(data2['minuto'].split(":")[0]);

        for (var i = 0; i < jugadoresAzul.length; i++) {
          final jugador = jugadoresAzul[i];
          final campeones = champsAzul[i];
          final kdaSplit = kdaAzul[i].split("/");
          final k = int.parse(kdaSplit[0]);
          final d = int.parse(kdaSplit[1]);
          final a = int.parse(kdaSplit[2]);
          final d2 = d == 0 ? 1 : d;

          if (!estad.containsKey(jugador)) {
            estad[jugador] = {
              "kills_t": k,
              "deaths_t": d,
              "assists_t": a,
              "minions": int.parse(minionsAzul[i]),
              "cs/m": double.parse((int.parse(minionsAzul[i]) / minuto).toStringAsFixed(2)),
              "cs_diff": int.parse(minionsAzul[i]) - int.parse(minionsRojo[i]),
              "kills_m": k,
              "partidos": 1,
              "kda_m": (k + a) / d2
            };
          } else {
            estad[jugador]!["kills_t"] += k;
            estad[jugador]!["deaths_t"] += d;
            estad[jugador]!["assists_t"] += a;
            estad[jugador]!["minions"] += int.parse(minionsAzul[i]);
            estad[jugador]!["cs/m"] += double.parse((int.parse(minionsAzul[i]) / minuto).toStringAsFixed(2));
            estad[jugador]!["cs_diff"] += int.parse(minionsAzul[i]) - int.parse(minionsRojo[i]);
            estad[jugador]!["kills_m"] += k;
            estad[jugador]!["partidos"] += 1;
            estad[jugador]!["kda_m"] += (k + a) / d2;
          }
        }

        for (var i = 0; i < jugadoresRojo.length; i++) {
          final jugador = jugadoresRojo[i];
          final campeones = champsRojo[i];
          final kdaSplit = kdaRojo[i].split("/");
          final k = int.parse(kdaSplit[0]);
          final d = int.parse(kdaSplit[1]);
          final a = int.parse(kdaSplit[2]);
          final d2 = d == 0 ? 1 : d;

          if (!estad.containsKey(jugador)) {
            estad[jugador] = {
              "kills_t": k,
              "deaths_t": d,
              "assists_t": a,
              "minions": int.parse(minionsRojo[i]),
              "cs/m": double.parse((int.parse(minionsRojo[i]) / minuto).toStringAsFixed(2)),
              "cs_diff": int.parse(minionsRojo[i]) - int.parse(minionsAzul[i]),
              "kills_m": k,
              "partidos": 1,
              "kda_m": (k + a) / d2
            };
          } else {
            estad[jugador]!["kills_t"] += k;
            estad[jugador]!["deaths_t"] += d;
            estad[jugador]!["assists_t"] += a;
            estad[jugador]!["minions"] += int.parse(minionsRojo[i]);
            estad[jugador]!["cs/m"] += double.parse((int.parse(minionsRojo[i]) / minuto).toStringAsFixed(2));
            estad[jugador]!["cs_diff"] += int.parse(minionsRojo[i]) - int.parse(minionsAzul[i]);
            estad[jugador]!["kills_m"] += k;
            estad[jugador]!["partidos"] += 1;
            estad[jugador]!["kda_m"] += (k + a) / d2;
          }
        }
      }
    }

    for (var jug in estad.keys) {
      estad[jug]!["minions"] = (estad[jug]!["minions"] / estad[jug]!["partidos"]).toStringAsFixed(2);
      estad[jug]!["cs/m"] = (estad[jug]!["cs/m"] / estad[jug]!["partidos"]).toStringAsFixed(2);
      estad[jug]!["cs_diff"] = (estad[jug]!["cs_diff"] / estad[jug]!["partidos"]).toStringAsFixed(2);
      estad[jug]!["kills_m"] = (estad[jug]!["kills_m"] / estad[jug]!["partidos"]).toStringAsFixed(2);
      estad[jug]!["kda_m"] = (estad[jug]!["kda_m"] / estad[jug]!["partidos"]).toStringAsFixed(2);
    }

    Map<String, List<List<dynamic>>> dictEstadF = {
      'kills_t': [],
      'deaths_t': [],
      'assists_t': [],
      'minions': [],
      'cs/m': [],
      'cs_diff': [],
      'kills_m': [],
      'kda_m': [],
    };



    List<MapEntry<String, Map<String, dynamic>>> topPlayers(String metric) {
      final sortedEntries = estad.entries.toList()
        ..sort((a, b) => b.value[metric].compareTo(a.value[metric]));

      final topEntries = <MapEntry<String, Map<String, dynamic>>>[];

      // Si la métrica es 'deaths_t', agregamos los 3 últimos jugadores.
      if (metric == 'deaths_t') {
        for (var i = sortedEntries.length - 1; i >= sortedEntries.length - 3 && i >= 0; i--) {
          topEntries.add(sortedEntries[i]);
        }
      } else {
        // Para otras métricas, agregamos los 3 primeros jugadores.
        for (var i = 0; i < 3 && i < sortedEntries.length; i++) {
          topEntries.add(sortedEntries[i]);
        }
      }

      return topEntries;
    }



    List<String> metrics = ['kills_t', 'deaths_t', 'assists_t', 'minions', 'cs/m', 'cs_diff', 'kills_m', 'kda_m'];

    for (var metric in metrics) {
      for (var player in topPlayers(metric)) {
        dictEstadF[metric]!.add([player.key, player.value[metric]]);
      }

    }

    //print(topPlayers);
    //print(dictEstadF);
    return(dictEstadF);

  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar:AppBar(
          backgroundColor: Color(0xff6200ff),
          title: _loadingPlayer ? Text(
            _competitionData.id.split("_")[0].toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xff6200ff), fontFamily: 'Sequel100'),
          )
              :Text(
            _competitionData.id.split("_")[0].toUpperCase(),
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
              child: FutureBuilder<Map<String, List<String>>>(
                future: _yearsAndSplitsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(); // Muestra un indicador de carga mientras se obtienen los datos
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    Map<String, List<String>> data = snapshot.data!;
                    List<String> years = data['years']!;
                    List<String> splits = data['splits']!;
                    String selectedYear = widget.id.split('_')[1];
                    String selectedSplit = widget.id.split('_')[2];
                    String selectedComp = widget.id.split('_')[0];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Container(
                          width: 65.0,
                          height: 65.0,
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
                              width: 50.0,
                              height: 50.0,
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/leclogo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                          children:[
                            DropdownButtonHideUnderline(
                              child:DropdownButton<String>(
                                style: TextStyle(
                                    fontFamily: "SequelSans", // Tamaño de fuente más pequeño
                                    color: Colors.white, fontSize: 17
                                ),

                                dropdownColor: Color(0xff6200ff),
                                iconEnabledColor: Colors.white,
                                value: selectedYear,
                                onChanged: (newValue) {

                                  String newId = 'lec_${newValue}_$selectedSplit';
                                  print(newId);
                                  if (newId!=widget.id){
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CompetitionDetailPage(id: newId),
                                      ),
                                    );
                                  }
                                },
                                items: years.map<DropdownMenuItem<String>>((String year) {
                                  return DropdownMenuItem<String>(
                                    value: year,
                                    child: Text(year),
                                  );
                                }).toList(),
                              ),
                            ),
                            DropdownButtonHideUnderline(
                              child:DropdownButton<String>(
                                style: TextStyle(
                                    fontFamily: "SequelSans", // Tamaño de fuente más pequeño
                                    color: Colors.white, fontSize: 17
                                ),
                                dropdownColor: Color(0xff6200ff),
                                iconEnabledColor: Colors.white,
                                value: selectedSplit,
                                onChanged: (newValue) {
                                  String newId = 'lec_${selectedYear}_$newValue';
                                  if (newId!=widget.id) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CompetitionDetailPage(id: newId),
                                      ),
                                    );
                                  }
                                },
                                items: splits.map<DropdownMenuItem<String>>((String split) {
                                  String splitText = '';
                                  switch (split) {
                                    case '1':
                                      splitText = 'Winter Split';
                                      break;
                                    case '2':
                                      splitText = 'Spring Split';
                                      break;
                                    case '3':
                                      splitText = 'Summer Split';
                                      break;
                                  // Agrega más casos según necesites
                                    default:
                                      splitText = split; // Mantén el valor original si no coincide con los casos anteriores
                                  }
                                  return DropdownMenuItem<String>(
                                    value: split,
                                    child: Text(splitText),
                                  );
                                }).toList(),
                              ),
                            ),
                          ]
                        ),// Espacio entre los dropdowns y el texto


                      ],
                    );
                  }
                },
              ),
            ),
            Expanded(
              child: DefaultTabController(
                length: 4,
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
                        Tab(text: 'Series'),
                        Tab(text: 'Clasificación'),
                        Tab(text: 'Estadisticas'),
                        Tab(text: 'Equipos'),
                      ],
                    ),
                  ),
                  body: TabBarView(
                    children: [
                      Container(
                        child: Center(
                          child: FutureBuilder<List<SerieData>>(
                            future: obtenerPartidosPorDia2(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return CircularProgressIndicator(); // Muestra un indicador de carga mientras se carga la lista de partidos
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}'); // Muestra un mensaje de error si ocurrió un error
                              } else {
                                List<SerieData> partidosPorDia = snapshot.data!;
                                // Ordenar los partidos por fecha
                                // Obtener la fecha actual
                                DateTime fechaActual = hora;
                                print(hora);
                                // Encontrar el índice del partido más cercano a la fecha actual
                                int indexInicial = partidosPorDia.length;
                                for (int i = 0; i < partidosPorDia.length; i++) {
                                  if (partidosPorDia[i].hora.isAfter(fechaActual) || partidosPorDia[i].hora.isAtSameMomentAs(fechaActual)) {
                                    indexInicial = i;
                                    break;
                                  }
                                }
                                // Crear el controlador de la lista y ajustarlo al índice inicial
                                final _controller = ScrollController(initialScrollOffset: indexInicial * 106.0); // Ajusta el valor 100.0 según sea necesario

                                return ListView.builder(
                                  controller: _controller,
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
                                                competition_id: widget.id,
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
                                                      fontSize: 24,
                                                      color: Color(0xff6200ff),
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
                        ),






                      ),
                      Container(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center, // Alineación vertical al centro
                              crossAxisAlignment: CrossAxisAlignment.center, // Alineación horizontal al centro
                              children: [
                                if (_competitionData.fase==2)
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
                                else if (_competitionData.fase>=3)
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
                      ),
                      Container(
                        child: Center(
                          child: FutureBuilder<Map<String, List<List<dynamic>>>>(
                            future: stats(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else {
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else {
                                  final statsData = snapshot.data!;

                                  return ListView.builder(
                                    itemCount: statsData.length,
                                    itemBuilder: (context, index) {
                                      final key = statsData.keys.elementAt(index);
                                      final data = statsData[key];

                                      return Container(
                                        margin: EdgeInsets.symmetric(vertical: 5,horizontal: 5), // Margen entre las columnas
                                        padding: EdgeInsets.all(10), // Espacio interno dentro del Container
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            color: Color(0xff6200ff),
                                            width: 3,
                                          ),
                                          borderRadius: BorderRadius.circular(10), // Bordes redondeados
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Center(
                                              child: Text(
                                                index == 0 ? "Más Kills" : index == 1 ? "Menos Muertes" :
                                                index == 2 ? "Más Asistencias" : index == 3 ? "Más CS/Partida" :
                                                index == 4 ? "Más CS/Min" : index == 5 ? "Más CS Diff" :
                                                index == 1 ? "Más Kills/Partida" : "KDA Medio",
                                                style: TextStyle(fontSize: 20, color: Color(0xff6200ff),fontFamily: "Sequel100"),
                                              ),
                                            ),
                                            ListView.builder(
                                              shrinkWrap: true,
                                              physics: NeverScrollableScrollPhysics(),
                                              itemCount: data!.length,
                                              itemBuilder: (context, index) {
                                                final item = data[index];
                                                return ListTile(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => PlayerDetailPage(ign: item[0]), // Nombre del jugador
                                                      ),
                                                    );
                                                  },
                                                  leading: FutureBuilder<DocumentSnapshot>(
                                                    future: FirebaseFirestore.instance
                                                        .collection('players_info')
                                                        .doc(item[0]) // Nombre del jugador
                                                        .get(),
                                                    builder: (context, snapshot) {
                                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                                        return CircularProgressIndicator();
                                                      }
                                                      if (snapshot.hasError) {
                                                        return Icon(Icons.error);
                                                      }
                                                      if (snapshot.hasData && snapshot.data!.exists) {
                                                        final jugadorInfoDoc = snapshot.data!;
                                                        final foto = jugadorInfoDoc['foto'] ?? 'null';

                                                        return Container(
                                                          width: 50.0,
                                                          height: 50.0,
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
                                                              width: 50.0,
                                                              height: 50.0,
                                                              child: ClipOval(
                                                                child: Image.network(
                                                                  foto,
                                                                  fit: BoxFit.cover,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        return Icon(Icons.person); // Puedes proporcionar un icono por defecto en caso de que no haya foto
                                                      }
                                                    },
                                                  ),
                                                  title: Text(
                                                    item[0], // Nombre del jugador
                                                    style: TextStyle(color: Color(0xff6200ff), fontFamily: "SequelSans"),
                                                  ),
                                                  subtitle: Text(
                                                    item[1].toString(), // Valor correspondiente a la métrica
                                                    style: TextStyle(color: Color(0xff6200ff), fontFamily: "SequelSans"),
                                                  ),
                                                );


                                              },
                                            ),

                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }
                              }
                            },
                          )
                          ,
                        ),
                      ),
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

                                      else {
                                        final jugadorInfoDoc = snapshot.data!;
                                        final foto = 'assets/${jugadorInfoDoc.id.toLowerCase()}.png'; // Ajustado para usar la ruta de asset

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
                                                builder: (context) => TeamDetailPage(tricode:teammates[index]),
                                              ),
                                            );
                                          },
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
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
                                                    width: 60.0,
                                                    height: 60.0,
                                                    child: ClipOval(
                                                      child: Image.asset(
                                                        foto,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 8), // Espacio entre la imagen y el texto
                                              Text(
                                                teammates[index],
                                                style: TextStyle(fontSize: 10.0, fontFamily: "Sequel100"),
                                              ), // Texto del compañero de equipo
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                            }
                          },
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
