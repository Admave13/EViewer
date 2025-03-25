import 'dart:math';
import 'package:proba1/TeamDetailPage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SerieDetailPage.dart';
import 'CompetitionDetailPage.dart';
import 'PartidoDetailPage.dart';
class PlayerData{
  final String ign;
  final String nombre;
  final String posicion;
  final String pais;
  final String twitter;
  final String instagram;
  final String equipo;
  final String foto;
  PlayerData({
  required this.ign,
  required this.nombre,
  required this.posicion,
    required this.equipo,
  this.twitter = 'no',
  this.instagram = 'no',
    this.foto = 'no',
    required this.pais,
  }
      );}
class PartidoData{
  final String compID;
  final String ID;
  final String ganador;
  final DateTime fecha;
  final String serieID;
  final String ladoAzul;
  final String ladoRojo;
  final int partido;
  final String kda;
  final String champ;
  PartidoData({
    required this.compID,
    required this.ID,
    required this.ganador,
    required this.fecha,
    required this.serieID,
    required this.ladoAzul,
    required this.ladoRojo,
    required this.partido,
    required this.kda,
    required this.champ,
});
}

class PlayerDetailPage extends StatefulWidget {
  final String ign;

  PlayerDetailPage({required this.ign});

  @override
  _PlayerDetailPageState createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends State<PlayerDetailPage> {
  late PlayerData _playerData =PlayerData(
    equipo: "Null",
    ign: "Null",
    nombre: "Null",
    posicion: "Null",
    pais:"Null",
  );
  late bool _loadingPlayer=true;

  @override
  void initState() {
    super.initState();
    _fetchPlayerData();
  }

  void _fetchPlayerData() async {
    final playerSnapshot = await FirebaseFirestore.instance
        .collection('players_info')
        .doc(widget.ign)
        .get();

    final playerData = playerSnapshot.data() as Map<String, dynamic>;
    setState(() {
      _playerData = PlayerData(
          ign: playerData['ign'],
          nombre: playerData['nombre'],
          posicion: playerData['posicion'],
          equipo: playerData['equipo'],
          pais: playerData['pais'],
          twitter:playerData["twitter"] ?? 'no',
          instagram:playerData["instagram"] ?? 'no',
          foto:playerData["foto"] ?? 'no'
      );
    });
    print(playerData["foto"]);
    _loadingPlayer = false;
  }

  Future<String> getMostPlayedChampion(String playerName) async {
    final recuentoCampeones = {};
    final db = FirebaseFirestore.instance;

    final filterAzul = FieldPath(['jugadores_azul']);
    final filterRojo = FieldPath(['jugadores_rojo']);

    final partidosConJugador = await db
        .collectionGroup('partido')
        .where(filterAzul, arrayContains: playerName)
        .get()
        .then((value) => value.docs)
        .catchError((error) => print("Error: $error"));

    final partidosConJugador2 = await db
        .collectionGroup('partido')
        .where(filterRojo, arrayContains: playerName)
        .get()
        .then((value) => value.docs)
        .catchError((error) => print("Error: $error"));

    final partidosConJugadorTotal = partidosConJugador + partidosConJugador2;

    for (var partido in partidosConJugadorTotal) {
      final data = partido.data();
      final jugadoresAzul = data['jugadores_azul'] ?? [];
      final champsAzul = data['champs_azul'] ?? [];
      final jugadoresRojo = data['jugadores_rojo'] ?? [];
      final champsRojo = data['champs_rojo'] ?? [];

      for (int i = 0; i < jugadoresAzul.length; i++) {
        if (jugadoresAzul[i] == playerName || jugadoresRojo[i] == playerName) {
          final campeon = champsAzul[i] ?? champsRojo[i];
          recuentoCampeones[campeon] = (recuentoCampeones[campeon] ?? 0) + 1;
        }
      }
    }

    final campeonMasJugado = recuentoCampeones.keys.isNotEmpty
        ? recuentoCampeones.keys.reduce((a, b) =>
    recuentoCampeones[a]! > recuentoCampeones[b]! ? a : b)
        : "No se encontraron datos";
    return campeonMasJugado.toString();
  }

  Future<List> getSeries() async {
    final fecha = DateTime(2023, 6, 26);
    final db = FirebaseFirestore.instance;
    String equipo=_playerData.equipo;
    print(_playerData.equipo);
    final filterEquipo1 = FieldPath(['equipo1']);
    final filterEquipo2 = FieldPath(['equipo2']);

    final seriesEquipo1 = await db
        .collectionGroup('series')
        .where(filterEquipo1, isEqualTo: equipo)
        .where('hora', isGreaterThan: Timestamp.fromDate(fecha))
        .orderBy('hora')
        .limit(1)
        .get()
        .then((value) => value.docs);

    final seriesEquipo2 = await db
        .collectionGroup('series')
        .where(filterEquipo2, isEqualTo: equipo)
        .where('hora', isGreaterThan: Timestamp.fromDate(fecha))
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

    List  sr=["${serieMasCercana!.data()['equipo1']} - ${serieMasCercana.data()['equipo2']}",serieMasCercana.id,competitionDoc!.id];
    return (sr);
    }

  Future<List<String>> getTeammates(String ign) async {
    List<String> teammates = [];

    QuerySnapshot jugadoresRef = await FirebaseFirestore.instance
        .collectionGroup('players')
        .where('ign', isEqualTo: ign)
        .get();

    for (QueryDocumentSnapshot jugadorRef in jugadoresRef.docs) {
      if (jugadorRef.reference.parent.parent != null) {
        String competicionId =
            jugadorRef.reference.parent.parent!.parent.parent!.id;
        String equipoId = jugadorRef.reference.parent.parent!.id;

        DocumentSnapshot competicionDoc = await FirebaseFirestore.instance
            .collection('competition')
            .doc(competicionId)
            .get();

        if (competicionDoc.exists && competicionDoc['en_activo'] == true) {
          QuerySnapshot jugadores = await FirebaseFirestore.instance
              .collection('competition')
              .doc(competicionId)
              .collection('teams')
              .doc(equipoId)
              .collection('players')
              .get();

          jugadores.docs.forEach((jugador) {
            if (jugador.id != ign) {
              teammates.add(jugador.id);
            }
          });
        }
      }
    }

    return teammates;
  }

  Future<List<PartidoData>> getMatchesForPlayer(String playerName) async {
    List<PartidoData> partidosList = [];

    var playersQuery = await FirebaseFirestore.instance
        .collectionGroup('players')
        .where('ign', isEqualTo: playerName)
        .get();

    for (var playerDoc in playersQuery.docs) {
      var competitionId =
          playerDoc.reference.parent.parent!.parent.parent!.id;
      var equipoId = playerDoc.reference.parent.parent!.id;


      var partidosQuery = await FirebaseFirestore.instance
          .collection('competition')
          .doc(competitionId)
          .collection('series')
          .where('equipo1', isEqualTo: equipoId)
          .get();

      for (var partidoDoc in partidosQuery.docs) {
        var esta = await FirebaseFirestore.instance
            .collection('competition')
            .doc(competitionId)
            .collection('series')
            .doc(partidoDoc.id)
            .collection('partido')
            .where('acabado', isEqualTo: true)
            .where('jugadores_azul', arrayContains: playerName)
            .get();

        for (var x in esta.docs) {
          int posicionAzul = (x['jugadores_azul'] as List).indexOf(playerName);
          var sp0= await FirebaseFirestore.instance.collection('competition')
              .doc(competitionId)
              .collection('series')
              .doc(partidoDoc.id)
              .collection('partido')
              .doc(x.id)
              .collection('situacion_partida')
              .doc("spfinal")
              .get();

          partidosList.add(PartidoData(
            ganador: x['ganador'] == equipoId ? 'W' : 'L',
            fecha: (partidoDoc['hora'] as Timestamp).toDate(),
            serieID: partidoDoc.id,
            ID: x.id,
            compID: competitionId,
            ladoAzul: x['lado_azul'],
            ladoRojo: x['lado_rojo'],
            partido: int.parse(x.id[1]),
            kda: sp0["kda_azul"][posicionAzul],
              champ:x['champs_azul'][posicionAzul]
          ));
        }
        var esta2 = await FirebaseFirestore.instance
            .collection('competition')
            .doc(competitionId)
            .collection('series')
            .doc(partidoDoc.id)
            .collection('partido')
            .where('acabado', isEqualTo: true)
            .where('jugadores_rojo', arrayContains: playerName)
            .get();

        for (var x in esta2.docs) {
          int posicionRojo = (x['jugadores_rojo'] as List).indexOf(playerName);
          var sp0= await FirebaseFirestore.instance.collection('competition')
              .doc(competitionId)
              .collection('series')
              .doc(partidoDoc.id)
              .collection('partido')
              .doc(x.id)
              .collection('situacion_partida')
              .doc("spfinal")
              .get();
          partidosList.add(PartidoData(
            ID: x.id,
            compID: competitionId,
            ganador: x['ganador'] == equipoId ? 'W' : 'L',
            fecha: (partidoDoc['hora'] as Timestamp).toDate(),
            serieID: partidoDoc.id,
            ladoAzul: x['lado_azul'],
            ladoRojo: x['lado_rojo'],
            partido: int.parse(x.id[1]),
              kda: sp0["kda_rojo"][posicionRojo],
              champ:x['champs_rojo'][posicionRojo]
          ));
        }
      }



      partidosQuery = await FirebaseFirestore.instance
          .collection('competition')
          .doc(competitionId)
          .collection('series')
          .where('equipo2', isEqualTo: equipoId)
          .get();

      for (var partidoDoc in partidosQuery.docs) {
        var esta = await FirebaseFirestore.instance
            .collection('competition')
            .doc(competitionId)
            .collection('series')
            .doc(partidoDoc.id)
            .collection('partido')
            .where('acabado', isEqualTo: true)
            .where('jugadores_rojo', arrayContains: playerName)
            .get();

        for (var x in esta.docs) {
          int posicionRojo = (x['jugadores_rojo'] as List).indexOf(playerName);
          var sp0= await FirebaseFirestore.instance.collection('competition')
              .doc(competitionId)
              .collection('series')
              .doc(partidoDoc.id)
              .collection('partido')
              .doc(x.id)
              .collection('situacion_partida')
              .doc("spfinal")
              .get();
          partidosList.add(PartidoData(
            ID: x.id,
            compID: competitionId,
            ganador: x['ganador'] == equipoId ? 'W' : 'L',
            fecha: (partidoDoc['hora'] as Timestamp).toDate(),
            serieID: partidoDoc.id,
            ladoAzul: x['lado_azul'],
            ladoRojo: x['lado_rojo'],
            partido: int.parse(x.id[1]),
              kda: sp0["kda_rojo"][posicionRojo],
              champ:x['champs_rojo'][posicionRojo]
          ));
        }
        var esta2 = await FirebaseFirestore.instance
            .collection('competition')
            .doc(competitionId)
            .collection('series')
            .doc(partidoDoc.id)
            .collection('partido')
            .where('acabado', isEqualTo: true)
            .where('jugadores_azul', arrayContains: playerName)
            .get();

        for (var x in esta2.docs) {
          int posicionAzul = (x['jugadores_azul'] as List).indexOf(playerName);
          var sp0= await FirebaseFirestore.instance.collection('competition')
              .doc(competitionId)
              .collection('series')
              .doc(partidoDoc.id)
              .collection('partido')
              .doc(x.id)
              .collection('situacion_partida')
              .doc("spfinal")
              .get();
          partidosList.add(PartidoData(
            ID: x.id,
            compID: competitionId,
            ganador: x['ganador'] == equipoId ? 'W' : 'L',
            fecha: (partidoDoc['hora'] as Timestamp).toDate(),
            serieID: partidoDoc.id,
            ladoAzul: x['lado_azul'],
            ladoRojo: x['lado_rojo'],
            partido: int.parse(x.id[1]),
              kda: sp0["kda_azul"][posicionAzul],
              champ:x['champs_azul'][posicionAzul]
          ));
        }
      }
    }
    partidosList.sort((a, b) {
      if (a.fecha != b.fecha) {
        return b.fecha.compareTo(a.fecha); // Ordena por fecha de más reciente a más lejana
      } else {
        return b.partido.compareTo(a.partido); // Ordena por partido de mayor a menor
      }
    });
    return partidosList;
  }

  Future<Map<String, List<Map<String, dynamic>>>> getPlayerTrajectory(String playerName) async {
    Map<String, List<Map<String, dynamic>>> competitionsByYearAndTeam = {};

    try {
      QuerySnapshot<Map<String, dynamic>> playersSnapshot =
      await FirebaseFirestore.instance
          .collectionGroup('players')
          .where('ign', isEqualTo: playerName)
          .get();

      await Future.forEach(playersSnapshot.docs, (playerDoc) async {
        String competitionId = playerDoc.reference.parent.parent!.parent.parent!.id;
        final competitionDoc = await playerDoc.reference.parent.parent!.parent.parent!.get();
        final competitionName = competitionDoc.data()?['nombre']; // Obtener el campo "nombre" de la competición
        String teamId = playerDoc.reference.parent.parent!.id;
        final teamDoc = await playerDoc.reference.parent.parent!.get();
        final teamPosition = teamDoc.data()?['position_final'] ?? "En Activo";

        // Obtener el año de la competición
        String year = competitionId.split('_')[1];

        // Si el año y el equipo no están en el diccionario, agregarlos
        competitionsByYearAndTeam.putIfAbsent('$year-$teamId', () => []);

        // Agregar la competición al diccionario con su nombre y ID
        competitionsByYearAndTeam['$year-$teamId']!.add({
          'name': competitionName,
          'id': competitionId,
          "position": teamPosition
        });
      });

      // Invertir el orden del mapa
      var reversedMap = Map.fromEntries(competitionsByYearAndTeam.entries.toList().reversed);

      // Invertir el orden de las listas dentro del mapa
      reversedMap.forEach((key, value) {
        value = value.reversed.toList(); // invertir la lista
        reversedMap[key] = value;
      });

      print(reversedMap);
      return reversedMap;
    } catch (e) {
      // Manejo de errores
      print("Error al obtener la trayectoria del jugador: $e");
      return {};
    }
  }





  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff6200ff),
          title: _loadingPlayer ? Text(
            _playerData.ign,
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xff6200ff), fontFamily: 'Sequel100'),
          )
              :Text(
            _playerData.ign,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontFamily: 'Sequel100'),
          ),
        ),
        body:
        _loadingPlayer
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
                                    _playerData.foto,
                                    fit: BoxFit.cover,
                                  )
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
                                  builder: (context) => TeamDetailPage(tricode: _playerData.equipo),
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
                                      'assets/${_playerData.equipo.toLowerCase()}.png',
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
            // Sección para las pantallas desplazables
            Expanded(
              child: DefaultTabController(
                length: 4, // Añadimos una pestaña adicional
                child: Scaffold(
                  appBar: AppBar(
                    toolbarHeight: 3,
                    automaticallyImplyLeading: false,
                    backgroundColor: Color(0xff6200ff),
                    bottom: TabBar(
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      labelStyle: TextStyle(fontSize: 16.0,fontFamily: 'SequelSans'),
                      unselectedLabelColor: Color(0xff2d0079),
                      isScrollable: true, // Permite el desplazamiento horizontal de las pestañas
                      labelPadding: EdgeInsets.symmetric(horizontal: 16.0), // Relleno horizontal
                      tabs: [
                        Tab(text: 'Información'),
                        Tab(text: 'Partidos'),
                        Tab(text: 'Trayectoria'),
                        Tab(text: 'Compañeros'), // Nueva pestaña
                      ],
                    ),
                  ),
                  body: TabBarView(
                    children: [
                      // Pestaña "Partidos" vacía
                      Container(
                        child: Center(
                          child: Column(
                            children: <Widget>[
                              Text('Datos Personales',style: TextStyle(fontSize: 25.0,fontFamily: "Sequel100",color: Color(0xff6200ff))),
                              Text('Posicion: ${_playerData.posicion}',style: TextStyle(fontFamily: "SequelSans",fontSize: 20.0)),
                              Text('Nombre: ${_playerData.nombre}',style: TextStyle(fontFamily: "SequelSans",fontSize: 20.0)),
                              Text('País: ${_playerData.pais}',style: TextStyle(fontFamily: "SequelSans",fontSize: 20.0)),
                              FutureBuilder<String>(
                                future: getMostPlayedChampion(_playerData.ign),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  }
                                  if (snapshot.hasData) {
                                    return Text('Campeón más jugado: ${snapshot.data}',style: TextStyle(fontFamily: "SequelSans",fontSize: 20.0));
                                  }
                                  return Text('No se pudo obtener el campeón más jugado');
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_playerData.twitter != "no") // Agrega esta condición
                                    GestureDetector(
                                      onTap: () {
                                        // Abre el enlace en el navegador cuando se toca la imagen
                                        launch('https://twitter.com/${_playerData.twitter}');
                                      },
                                      child: Image.asset(
                                        'assets/logo_twitter.png', // Reemplaza con la ruta de tu imagen local
                                        width: 50.0,
                                        height: 50.0,
                                      ),
                                    ),
                                  SizedBox(width: 30),
                                  if (_playerData.instagram != "no") // Agrega esta condición
                                    GestureDetector(
                                      onTap: () {
                                        // Abre el enlace en el navegador cuando se toca la imagen
                                        launch('https://instagram.com/${_playerData.instagram}');
                                      },
                                      child: Image.asset(
                                        'assets/logo_ig.png', // Reemplaza con la ruta de tu imagen local
                                        width: 50.0,
                                        height: 50.0,
                                      ),
                                    ),
                                ],
                              ),
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
                                    final serieId = data[1];
                                    final competitionId = data[2];

                                    // Realizar el split de data[0]
                                    final teams = data[0].split(' - ');
                                    final team1 = teams[0].trim();
                                    final team2 = teams[1].trim();

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
                                          backgroundColor: Colors.white,
                                          foregroundColor: Color(0xff6200ff),
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
                                                // Imagen de equipo 1
                                                Image.asset(
                                                  'assets/${team1.toLowerCase()}.png', // Asegúrate de que los nombres de las imágenes sean correctos
                                                  width: 40,
                                                  height: 40,
                                                ),
                                                // Texto del siguiente partido
                                                SizedBox(
                                                  width: 200,
                                                  child: Text(
                                                    '${team1} - ${team2}',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      color: Color(0xff6200ff),
                                                    ),
                                                  ),
                                                ),
                                                // Imagen de equipo 2
                                                Image.asset(
                                                  'assets/${team2.toLowerCase()}.png', // Asegúrate de que los nombres de las imágenes sean correctos
                                                  width: 40,
                                                  height: 40,
                                                ),
                                              ],
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


                              // Agrega más Text widgets según sea necesario para otros valores
                            ],
                          ),
                        ),
                      ),
                      // Pestaña "Previa" vacía
                      Container(
                        child: Center(
                          child: FutureBuilder<List<PartidoData>>(
                            future: getMatchesForPlayer(_playerData.ign), // Reemplaza 'nombre del jugador' por el nombre real del jugador
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
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 7.0),
                                        title: ElevatedButton(
                                          onPressed: () {
                                            // Navegar a la pantalla de detalle de la serie con los datos de la serie seleccionada
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => PartidoDetailPage(
                                                  id: partido.ID,
                                                  competition_id: partido.compID,
                                                  serie_id: partido.serieID,
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
                                            maximumSize: Size(300, 75), // Ajusta según sea necesario
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.white,
                                            elevation: 0.1,
                                            side: BorderSide(width: 1.7, color: Color(0xff6200ff)),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 30,  // Ajusta el ancho según sea necesario
                                                height: 30, // Ajusta la altura según sea necesario
                                                color: partido.ganador == "W" ? Color(0xff04e2bc) : Color(0xffe2046c),
                                                child: Center(
                                                  child: Text(
                                                    '${partido.ganador}',
                                                    style: TextStyle(
                                                        color: Colors.white, // Color del texto "W"
                                                        fontWeight: FontWeight.bold,
                                                        fontFamily: "SequelSans"
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 18.0), // Espacio entre el ganador y el resto del texto
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          '${partido.ladoAzul}',
                                                          textAlign: TextAlign.left,
                                                          style: TextStyle(
                                                            fontSize: 15.0,
                                                            fontFamily: "Sequel100",
                                                            color: Color(0xff6200ff),
                                                          ),
                                                        ),
                                                        SizedBox(width: 5),
                                                        Image.asset(
                                                          'assets/${partido.ladoAzul.toLowerCase()}.png',
                                                          width: 30,
                                                          height: 30,
                                                        ),
                                                        SizedBox(width: 10),
                                                        Text(
                                                          '-',
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: 17.0,
                                                            fontFamily: "Sequel100",
                                                            color: Color(0xff6200ff),
                                                          ),
                                                        ),
                                                        SizedBox(width: 10),
                                                        Image.asset(
                                                          'assets/${partido.ladoRojo.toLowerCase()}.png',
                                                          width: 30,
                                                          height: 30,
                                                        ),
                                                        SizedBox(width: 5),
                                                        Text(
                                                          '${partido.ladoRojo}',
                                                          textAlign: TextAlign.right,
                                                          style: TextStyle(
                                                            fontSize: 15.0,
                                                            fontFamily: "Sequel100",
                                                            color: Color(0xff6200ff),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      'Mapa ${partido.partido}',
                                                      style: TextStyle(
                                                        fontSize: 15.0,
                                                        fontFamily: "SequelSans",
                                                        color: Color(0xff6200ff),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 18.0),
                                              Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 35.0,
                                                    height: 35.0,
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
                                                        width: 35.0,
                                                        height: 35.0,
                                                        child: ClipOval(
                                                          child: Image.network(
                                                            "https://ddragon.leagueoflegends.com/cdn/14.10.1/img/champion/${partido.champ}.png",
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '${partido.champ}',
                                                    style: TextStyle(
                                                      color: Color(0xff6200ff), // Color del texto "W"
                                                      fontFamily: "SequelSans",
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${partido.kda}',
                                                    style: TextStyle(
                                                      color: Color(0xff6200ff), // Color del texto "W"
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: "SequelSans",
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        )

                                      // Agrega cualquier otra información relevante aquí
                                    );
                                  },
                                );
                              }
                            },
                          ),
                        )

                      ),
                      // Pestaña "Clasificación" vacía
                      Container(
                        child: Center(
                          child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                            future: getPlayerTrajectory(_playerData.ign),
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
                                    String key = entry.key;
                                    List<Map<String, dynamic>> competitions = entry.value;

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
                                                Image.asset(
                                                  expanded ? 'assets/${_playerData.equipo.toLowerCase()}2.png' : 'assets/${_playerData.equipo.toLowerCase()}.png',
                                                  width: 30,
                                                  height: 30,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  '$key - ${competitions.first['position'] is int ? '${competitions.first['position']}º' : competitions.first['position']}',
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
                                            children: competitions.map((competition) {
                                              return ListTile(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => CompetitionDetailPage(id: competition['id']),
                                                    ),
                                                  );
                                                },
                                                title: Row(
                                                  children: [
                                                    Image.asset(
                                                      expanded ? 'assets/lec2.png' : 'assets/lec.png',
                                                      width: 30,
                                                      height: 30,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      competition['name'],
                                                      style: TextStyle(color: Colors.white, fontFamily: "SequelSans"),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      competition['position'] != null && int.tryParse(competition['position'].toString()) != null
                                                          ? '${int.parse(competition['position'].toString())}º'
                                                          : "-",
                                                      style: TextStyle(color: Colors.white, fontFamily: "Sequel100"),
                                                    ),
                                                  ],
                                                ),
                                              );
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
                      ),
                      // Pestaña "Compañeros" vacía
                      Container(
                        child: FutureBuilder<List<String>>(
                          future: getTeammates(widget.ign),
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
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              SizedBox(height: 8), // Espacio entre la imagen y el texto
                                              Text(teammates[index],
                                                style: TextStyle(fontSize: 10.0, fontFamily: "Sequel100"),
                                              ), // Texto del compañero de equipo
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
                      ),

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

