import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:proba1/SerieDetailPage2.dart';
import 'TeamDetailPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class PartidoData {
  final String id;
  final String equipo1;
  final String equipo2;
  final String serie_id;
  final bool acabado;
  final String ganador;
  final List<dynamic> champs_azul;
  final List<dynamic> champs_rojo;
  final List<dynamic> jugadores_azul;
  final List<dynamic> jugadores_rojo;
  final List<dynamic> runes_azul;
  final List<dynamic> runes_rojo;

  PartidoData({
    required this.id,
    required this.equipo1,
    required this.equipo2,
    required this.serie_id,
    required this.acabado,
    required this.ganador,
    required this.champs_azul,
    required this.champs_rojo,
    required this.jugadores_azul,
    required this.jugadores_rojo,
    required this.runes_azul,
    required this.runes_rojo,
  });
}

class SituacionData {
  final String sp;
  final List<dynamic> kda_azul;
  final List<dynamic> kda_rojo;
  final List<dynamic> minions_azul;
  final List<dynamic> minions_rojo;
  final String minuto;
  final String oro_azul;
  final String oro_rojo;
  final String kills_azul;
  final String kills_rojo;
  final String torres_azul;
  final String torres_rojo;

  SituacionData({
    required this.kda_azul,
    required this.kda_rojo,
    required this.sp,
    required this.minions_azul,
    required this.minions_rojo,
    required this.minuto,
    required this.oro_azul,
    required this.oro_rojo,
    required this.kills_azul,
    required this.kills_rojo,
    required this.torres_azul,
    required this.torres_rojo,
  });
}

class PartidoDetailPage extends StatefulWidget {
  final String id;
  final String equipo1;
  final String equipo2;
  final String serie_id;
  final String competition_id;

  PartidoDetailPage({required this.id,required this.competition_id,required this.serie_id,required this.equipo1,required this.equipo2});

  @override
  _PartidoDetailPageState createState() => _PartidoDetailPageState();
}

class _PartidoDetailPageState extends State<PartidoDetailPage> {
  late bool _juansama=false; //inicializar antes si existe sp0
  late bool _loadingPartido = true;
  late int showingTooltipSpot=-1;
  late PartidoData _partidoData = PartidoData(
    equipo1: "Null",
    equipo2: "Null",
    id:"",
    serie_id:"",
    acabado: false,
    ganador: "Null",
    champs_azul:["","","","",""],
    champs_rojo:["","","","",""],
    jugadores_azul:["","","","",""],
    jugadores_rojo:["","","","",""],
      runes_azul:["","","","",""],
      runes_rojo:["","","","",""]
  );

  late SituacionData _situacionFinal = SituacionData(
    kda_azul: ["","","","",""],
    kda_rojo: ["","","","",""],
    sp:"",
    minions_azul:["","","","",""],
    minions_rojo:["","","","",""],
    minuto:"",
    oro_azul:"2.5k",
    oro_rojo:"2.5k",
    kills_azul:"",
    kills_rojo:"",
    torres_azul:"",
    torres_rojo:"",
  );

  late SituacionData _situacionActual = SituacionData(
    kda_azul: ["","","","",""],
    kda_rojo: ["","","","",""],
    sp:"",
    minions_azul:["","","","",""],
    minions_rojo:["","","","",""],
    minuto:"",
    oro_azul:"2.5k",
    oro_rojo:"2.5k",
    kills_azul:"",
    kills_rojo:"",
    torres_azul:"",
    torres_rojo:"",
  );

  late List<int> _gd =[];
  late List<DocumentSnapshot> _filteredGp=[];
  List<int> showingTooltipOnSpots=[];
  List<double> stops=[];
  late bool _selected=false;
  bool _loadingPartidos2 = true;


  @override
  void initState() {
    super.initState();
    _fetchPartidoData();
    _fetchSituacionFinal();
    _fetchSituacionFinal2();
    fetchAndProcessGoldDifference();
  }

  void _fetchPartidoData() async {
    final partidoSnapshot = await FirebaseFirestore.instance
        .collection('competition')
        .doc(widget.competition_id)
        .collection('series')
        .doc(widget.serie_id)
        .collection("partido")
        .doc(widget.id)
        .get();

    final partidoData = partidoSnapshot.data() as Map<String, dynamic>;
    _juansama = false;

    // Verificar si existe el documento "sp0" en la colección "situacion_partida"
    final situacionPartidaSnapshot = await FirebaseFirestore.instance
        .collection('competition')
        .doc(widget.competition_id)
        .collection('series')
        .doc(widget.serie_id)
        .collection("partido")
        .doc(widget.id)
        .collection("situacion_partida")
        .doc("sp0")
        .get();

    if (situacionPartidaSnapshot.exists) {
      _juansama = true;
    }

    setState(() {
      // Comprobar si runes_azul es nulo antes de asignar su valor
      final runesAzul = partidoData["runes_azul"];
      final runesRojo = partidoData["runes_rojo"];
      _partidoData = PartidoData(
          equipo1: partidoData["lado_azul"],
          equipo2: partidoData["lado_rojo"],
          id: widget.id,
          serie_id: widget.serie_id,
          acabado: partidoData["acabado"],
          ganador: partidoData["ganador"],
          champs_azul: partidoData["champs_azul"],
          champs_rojo: partidoData["champs_rojo"],
          jugadores_azul: partidoData["jugadores_azul"],
          jugadores_rojo: partidoData["jugadores_rojo"],
          // Asignar runes_azul solo si no es nulo, de lo contrario, conservar el valor anterior
          runes_azul: runesAzul != null ? runesAzul : _partidoData.runes_azul,
        runes_rojo: runesRojo != null ? runesRojo : _partidoData.runes_rojo,
      );

      _loadingPartido = false;
    });

  }

  void _fetchSituacionFinal() {
    FirebaseFirestore.instance
        .collection('competition')
        .doc(widget.competition_id)
        .collection('series')
        .doc(widget.serie_id)
        .collection("partido")
        .doc(widget.id)
        .collection("situacion_partida")
        .doc("spfinal")
        .snapshots()
        .listen((situacionSnapshot) {
      if (mounted) {
        final situacionFinal = situacionSnapshot.data() as Map<String, dynamic>;
        print(widget.serie_id);
        setState(() {
          _situacionFinal = SituacionData(
            kda_azul: situacionFinal["kda_azul"],
            kda_rojo: situacionFinal["kda_rojo"],
            sp: situacionSnapshot.id,
            minions_azul: situacionFinal["minions_azul"],
            minions_rojo: situacionFinal["minions_rojo"],
            minuto: situacionFinal["minuto"],
            oro_azul: situacionFinal["oro_azul"],
            oro_rojo: situacionFinal["oro_rojo"],
            kills_azul: situacionFinal["kills_azul"],
            kills_rojo: situacionFinal["kills_rojo"],
            torres_azul: situacionFinal["torres_azul"],
            torres_rojo: situacionFinal["torres_rojo"],
          );
        });
      }
    });
  }

  void fetchAndProcessGoldDifference() {
    FirebaseFirestore.instance
        .collection('competition')
        .doc(widget.competition_id)
        .collection('series')
        .doc(widget.serie_id)
        .collection("partido")
        .doc(widget.id)
        .collection("situacion_partida")
        .snapshots()
        .listen((QuerySnapshot situacionSnapshot) {
      List<DocumentSnapshot> filteredGp = situacionSnapshot.docs.where((doc) => doc.id != "spfinal").toList();

      filteredGp.sort((a, b) => int.parse(a.id.substring(2)).compareTo(int.parse(b.id.substring(2))));

      List<int> goldDifferences = [];

      for (DocumentSnapshot doc in filteredGp) {
        String oroAzulStr = doc["oro_azul"];
        String oroRojoStr = doc["oro_rojo"];

        int oroAzul = (double.parse(oroAzulStr.replaceAll("k", "")) * 1000).toInt();
        int oroRojo = (double.parse(oroRojoStr.replaceAll("k", "")) * 1000).toInt();

        int goldDiff = oroAzul - oroRojo;
        goldDifferences.add(goldDiff);
      }

      setState(() {
        _filteredGp=filteredGp;
        _gd = goldDifferences;
      });
      if (_gd.length!=0){
        double minY = _gd.reduce((value, element) => value < element ? value : element).toDouble();
        double maxY = _gd.reduce((value, element) => value > element ? value : element).toDouble();
        double absMinY = minY.abs();
        double absMaxY = maxY.abs();
        double closestToZero = absMinY < absMaxY ? absMinY : absMaxY;
        double sumAbs = absMinY + absMaxY;
        double ratio = closestToZero / sumAbs;
        setState(() {
          if(absMinY>absMaxY){
            stops=[0,ratio,ratio,2*ratio];
          }else{
            stops=[1-(2*ratio),1-ratio,1-ratio,1];
          }
        });
      }
    });
  }

  void _fetchSituacionFinal2() {
    FirebaseFirestore.instance
        .collection('competition')
        .doc(widget.competition_id)
        .collection('series')
        .doc(widget.serie_id)
        .collection("partido")
        .doc(widget.id)
        .collection("situacion_partida")
        .doc(showingTooltipSpot == -1 ? "spfinal" : _filteredGp[showingTooltipSpot].id)
        .snapshots()
        .listen((situacionSnapshot) {
      if (mounted) {
        final situacionActual = situacionSnapshot.data() as Map<String, dynamic>;
        print(widget.serie_id);
        setState(() {
          _situacionActual = SituacionData(
            kda_azul: situacionActual["kda_azul"],
            kda_rojo: situacionActual["kda_rojo"],
            sp: situacionSnapshot.id,
            minions_azul: situacionActual["minions_azul"],
            minions_rojo: situacionActual["minions_rojo"],
            minuto: situacionActual["minuto"],
            oro_azul: situacionActual["oro_azul"],
            oro_rojo: situacionActual["oro_rojo"],
            kills_azul: situacionActual["kills_azul"],
            kills_rojo: situacionActual["kills_rojo"],
            torres_azul: situacionActual["torres_azul"],
            torres_rojo: situacionActual["torres_rojo"],
          );
        });
      }
    });
  }

  String _formatValue(double value) {
    if (value.abs() < 1000) {
      return '${value.toInt()}';
    } else if (value.abs() >= 1000 && value.abs() < 10000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    } else {
      return '${(value / 1000).toInt()}k';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cambiar por el valor apropiado
    double oroAzul = double.parse(_situacionFinal.oro_azul.replaceAll('k', '')) * 1000.0;
    double oroRojo = double.parse(_situacionFinal.oro_rojo.replaceAll('k', '')) * 1000.0;
    double diferenciaOro = oroAzul - oroRojo;
    String formattedDifference = (diferenciaOro / 1000).toStringAsFixed(1) + "K";
    return Material(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff6200ff),
          title: _loadingPartido ? Text(
            "Mapa ${widget.id[1]}",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xff6200ff), fontFamily: 'Sequel100'),
          )
              :Text(
            "Mapa ${widget.id[1]}",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontFamily: 'Sequel100'),
          ),
        ),

        body: _loadingPartido
            ? Center(child: CircularProgressIndicator())
            : Stack(
          children: [
            Column(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height / 5,
                  alignment: Alignment.center,
                  color: Color(0xff6200ff),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Primer equipo
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TeamDetailPage(tricode: widget.equipo1),
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
                                      color: Color(0xff2d0079),
                                      width: 2.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: 45.0,
                                      height: 45.0,
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/${widget.equipo1.toLowerCase()}.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TeamDetailPage(tricode: widget.equipo1),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    widget.equipo1,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white, fontFamily: 'Sequel100'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Texto del medio
                          SizedBox(width: 55),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _partidoData.acabado
                                ? (_partidoData.ganador == _partidoData.equipo1 ? "1 - 0" : "0 - 1")
                                : ("${_situacionFinal.minuto.split(":")[0]}'"),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontFamily: 'Sequel100', fontSize: 25.0),
                              ),
                              SizedBox(height: 25),
                            ],
                          ),
                          SizedBox(width: 55),
                          // Segundo equipo
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TeamDetailPage(tricode: widget.equipo2),
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
                                      color: Color(0xff2d0079),
                                      width: 2.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: 45.0,
                                      height: 45.0,
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/${widget.equipo2.toLowerCase()}.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TeamDetailPage(tricode: widget.equipo2),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    widget.equipo2,
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
                Expanded(
                  child: _juansama
                      ? _buildTabControllerWithBothTabs()
                      : _buildTabControllerWithSummaryTab(),
                ),
              ],
            ),
            Positioned(
              left: -20, // Cambiar este valor para ajustar la posición horizontal
              top: 140, // Cambiar este valor para ajustar la posición vertical
              child: Container(
                width: MediaQuery.of(context).size.width / 2 - 65, // Ancho ajustado
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xff04e2bc),
                  borderRadius: BorderRadius.circular(15), // Bordes redondeados
                  border: Border.all(color: Color(0xff2d0079), width: 2.5), // Borde negro
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0), // Ajuste de padding a la derecha
                  child: Align(
                    alignment: Alignment.centerRight, // Alinear el texto a la derecha
                    child: Text(
                      "${_situacionFinal.kills_azul}",
                      style: TextStyle(color: Color(0xff2d0079),fontFamily: 'Sequel100',fontSize: 23.0),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left:
              //diferenciaOro >= 10000 ? MediaQuery.of(context).size.width / 2 - 35 :
              MediaQuery.of(context).size.width / 2 - 60,
              top: 110,
              child: Text(
                ('+') +
                    (diferenciaOro >= 0 ? formattedDifference : formattedDifference.substring(1)), // Elimina el "-" si es negativo
                style: TextStyle(
                  color: diferenciaOro >= 0 ? Color(0xff04e2bc) : Color(0xfff9136f),
                  fontSize: 30,
                  fontFamily: "Sequel100"
                ),
              ),
            ),
            Positioned(
              right: -20, // Cambiar este valor para ajustar la posición horizontal
              top: 140, // Cambiar este valor para ajustar la posición vertical
              child: Container(
                width: MediaQuery.of(context).size.width / 2 - 65, // Ancho ajustado
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xfff9136f),
                  borderRadius: BorderRadius.circular(15), // Bordes redondeados
                  border: Border.all(color: Color(0xff2d0079), width: 2.5), // Borde negro
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0), // Ajuste de padding a la derecha
                  child: Align(
                    alignment: Alignment.centerLeft, // Alinear el texto a la derecha
                    child: Text(
                      "${_situacionFinal.kills_rojo}",
                      style: TextStyle(color: Color(0xff2d0079),fontFamily: 'Sequel100',fontSize: 23.0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabControllerWithBothTabs() {
    return DefaultTabController(
      length: 1,
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
            isScrollable: false,
            tabs: [
              Tab(text: 'Resumen'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              child: Stack(
                children: [
                  Container(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 60),
                          _buildGoldDiffChart(),
                          SizedBox(height: 40),
                          Text("Minuto ${_situacionActual.minuto.split(":")[0] == '00' ? '0' : _situacionActual.minuto.split(":")[0]}",
                              style:TextStyle(fontFamily: "Sequel100",color: Color(0xff6200ff),fontSize: 20)),
                          buildDataTableWidget2(),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10, // Ajusta la posición del botón en la parte superior
                    right: 10, // Ajusta la posición del botón a la derecha
                    child: _selected ? ElevatedButton(
                      onPressed: () {
                        // Llama a la función que reinicializa showingTooltipOnSpots
                        reinicializarShowingTooltipOnSpots();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff6200ff), // Color de fondo del botón
                      ),
                      child: Text('R', style: TextStyle(color: Colors.white)),
                    ) : SizedBox(), // Mostrar el botón solo si _selected es true
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabControllerWithSummaryTab() {
    return DefaultTabController(
      length: 1, // Solo un tab para Resumen
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
            isScrollable: false,
            tabs: [
              Tab(text: 'Resumen'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Container(
              child: Center(
                child: buildDataTableWidget2(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDataTableWidget2({double initialPosition = 50, double spaceBetween = 100}) {
    print(_situacionActual.minions_azul);
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Container(
        margin: EdgeInsets.all(10.0),
        child: Column(
          children: [
            for (int i = 0; i < 5; i++)
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          _navigateToTextScreen(
                            _partidoData.equipo1,
                            _partidoData.jugadores_azul[i],
                            _partidoData.champs_azul[i],
                            _situacionActual.minions_azul[i],
                            _situacionActual.kda_azul[i],
                            _situacionActual.minuto.split(":")[0],
                            _partidoData.runes_azul[i],
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 45.0,
                                    height: 45.0,
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
                                        width: 45.0,
                                        height: 45.0,
                                        child: ClipOval(
                                          child: Image.network(
                                            "https://ddragon.leagueoflegends.com/cdn/14.10.1/img/champion/${_partidoData.champs_azul[i]}.png",
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: -10,
                                    bottom: 0,
                                    child: Container(
                                      width: 25.0,
                                      height: 25.0,
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
                                          width: 20.0,
                                          height: 20.0,
                                          child: ClipOval(
                                            child: FutureBuilder<DocumentSnapshot>(
                                              future: FirebaseFirestore.instance
                                                  .collection('players_info')
                                                  .doc(_partidoData.jugadores_azul[i])
                                                  .get(),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return CircularProgressIndicator();
                                                }
                                                final foto = snapshot.data!['foto'];
                                                return Image.network(
                                                  foto,
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 17),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${_partidoData.jugadores_azul[i]}",
                                    style:TextStyle(fontFamily: "Sequel100",fontSize: 8,color: Color(0xff6200ff)) ,),
                                  Text("${_situacionActual.kda_azul[i]}",
                                      style:TextStyle(fontFamily: "SequelSans",color: Color(0xff6200ff))),
                                  Text("${_situacionActual.minions_azul[i]} CS",
                                      style:TextStyle(fontFamily: "SequelSans",color: Color(0xff6200ff))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: (_situacionActual.minions_azul[i] != null && _situacionActual.minions_rojo[i] != null)
                            ? int.parse(_situacionActual.minions_azul[i]) - int.parse(_situacionActual.minions_rojo[i]) > 0
                            ? Color(0xff04e2bc)
                            : int.parse(_situacionActual.minions_azul[i]) - int.parse(_situacionActual.minions_rojo[i]) < 0
                            ? Color(0xfff9136f)
                            : Colors.white
                            : Colors.white,
                        border: Border.all(
                          color: Color(0xff2d0079),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "${(_situacionActual.minions_azul[i] != null && _situacionActual.minions_rojo[i] != null)
                              ? '${_situacionActual.minions_azul[i] != null && _situacionActual.minions_rojo[i] != null ? '+' : ''}${(int.parse(_situacionActual.minions_azul[i]) - int.parse(_situacionActual.minions_rojo[i])).abs()}'
                              : ""}",
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Color(0xff2d0079), fontFamily: "SequelSans"
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          _navigateToTextScreen(
                            _partidoData.equipo2,
                            _partidoData.jugadores_rojo[i],
                            _partidoData.champs_rojo[i],
                            _situacionActual.minions_rojo[i],
                            _situacionActual.kda_rojo[i],
                            _situacionActual.minuto.split(":")[0],
                            _partidoData.runes_rojo[i],
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end, // Ajuste aquí
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("${_partidoData.jugadores_rojo[i]}",
                                      style:TextStyle(fontFamily: "Sequel100",fontSize: 8,color: Color(0xff6200ff))),
                                  Text("${_situacionActual.kda_rojo[i]}",
                                      style:TextStyle(fontFamily: "SequelSans",color: Color(0xff6200ff))),
                                  Text("${_situacionActual.minions_rojo[i]} CS",
                                      style:TextStyle(fontFamily: "SequelSans",color: Color(0xff6200ff))),

                                ],
                              ),
                              SizedBox(width: 17),
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 45.0,
                                    height: 45.0,
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
                                        width: 45.0,
                                        height: 45.0,
                                        child: ClipOval(
                                          child: Image.network(
                                            "https://ddragon.leagueoflegends.com/cdn/14.10.1/img/champion/${_partidoData.champs_rojo[i]}.png",
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: -10,
                                    bottom: 0,
                                    child: Container(
                                      width: 25.0,
                                      height: 25.0,
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
                                          width: 20.0,
                                          height: 20.0,
                                          child: ClipOval(
                                            child: FutureBuilder<DocumentSnapshot>(
                                              future: FirebaseFirestore.instance
                                                  .collection('players_info')
                                                  .doc(_partidoData.jugadores_rojo[i])
                                                  .get(),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return CircularProgressIndicator();
                                                }
                                                final foto = snapshot.data!['foto'];
                                                return Image.network(
                                                  foto,
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildGoldDiffChart() {
    final goldDiffData = _gd;
    List<FlSpot> spots = List.generate(
      goldDiffData.length,
          (index) => FlSpot(index.toDouble(), goldDiffData[index].toDouble()),
    );

    final _lineBarsData = [
      LineChartBarData(
        showingIndicators: showingTooltipOnSpots,
        spots: spots,
        isCurved: false,
        dotData: FlDotData(show: false),
        //gradient: LinearGradient(
        //  colors: [Colors.blue, Colors.blue, Colors.red, Colors.red],
        //  stops: stops,
        //  begin: Alignment.topCenter,
        //  end: Alignment.bottomCenter,
        //),
        color:Color(0xff6200ff).withOpacity(0.7),
          aboveBarData: BarAreaData(
            show: true,
            spotsLine: BarAreaSpotsLine(
              applyCutOffY: true,
              checkToShowSpotLine: (spot) => spot.y > 0,
            ),
            applyCutOffY: true,
            gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors:
                [Color(0xfff9136f), Color(0xfff9136f)]
                    .map((color) => color.withOpacity(0.7))
                    .toList()
            )),
        belowBarData: BarAreaData(
          show: true,
          spotsLine: BarAreaSpotsLine(
            applyCutOffY: true,
            checkToShowSpotLine: (spot) => spot.y < 0,
          ),
          applyCutOffY: true,
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors:
                [Color(0xff04e2bc), Color(0xff04e2bc)]
                .map((color) => color.withOpacity(0.7))
                .toList()
          ),

        ),
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Color(0xff6200ff),
          width: 3,
        ),
        borderRadius: BorderRadius.circular(10), // Bordes redondeados
      ),
      width: 370, // ajusta el ancho según tus necesidades
      height: 220, // ajusta el alto según tus necesidades
      padding: EdgeInsets.all(16), // Añade un padding de 16 píxeles alrededor del contenido
      child: LineChart(
        LineChartData(
          lineBarsData: _lineBarsData,
          borderData: FlBorderData(
            border: const Border(),
          ),
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: 10000,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    '${_formatValue(value.abs())}',
                    style: const TextStyle(
                      fontFamily: "SequelSans",
                      fontSize: 12,
                      color: Color(0xff6200ff),
                    ),
                  ),
                ),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          showingTooltipIndicators: showingTooltipSpot != -1
              ? [
            ShowingTooltipIndicators([
              LineBarSpot(
                  _lineBarsData[0], showingTooltipSpot, spots[showingTooltipSpot]),
            ])
          ]
              : [],
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: false,
            touchCallback: (event, response) {
              if (response?.lineBarSpots != null && event is FlTapUpEvent) {
                setState(() {
                  final spotIndex = response?.lineBarSpots?[0].spotIndex ?? -1;
                  if (spotIndex == showingTooltipSpot) {
                    showingTooltipOnSpots.remove(spotIndex);
                    showingTooltipSpot = -1;
                    _selected = false;
                    _fetchSituacionFinal2();
                  } else {
                    showingTooltipOnSpots.remove(showingTooltipSpot);
                    showingTooltipOnSpots.add(spotIndex);
                    showingTooltipSpot = spotIndex;
                    _selected = true;
                    _fetchSituacionFinal2();
                  }
                });
              }
            },
            mouseCursorResolver: (FlTouchEvent event, LineTouchResponse? response) {
              if (response == null || response.lineBarSpots == null) {
                return SystemMouseCursors.basic;
              }
              return SystemMouseCursors.click;
            },
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((index) {
                final spot = barData.spots[index];
                Color dotColor;
                if (spot.y < 0) {
                  dotColor = Color(0xfff9136f).withOpacity(0.9); // Color rojo si y es negativo
                } else if (spot.y > 0) {
                  dotColor = Color(0xff04e2bc).withOpacity(0.9); // Color azul si y es positivo
                } else {
                  dotColor = Colors.black.withOpacity(0.9); // Color negro si y es 0
                }
                return TouchedSpotIndicatorData(
                  const FlLine(
                    color: Color(0xff6200ff),
                    strokeWidth: 0,
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                          radius: 8,
                          color: dotColor,
                          strokeWidth: 2,
                          strokeColor: Color(0xff6200ff).withOpacity(0.3),
                        ),
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) {
                if (touchedSpot.y < 0) {
                  return Color(0xfff9136f).withOpacity(0.9); // Color rojo si y es negativo
                } else if (touchedSpot.y > 0) {
                  return Color(0xff04e2bc).withOpacity(0.9); // Color azul si y es positivo
                } else {
                  return Colors.black.withOpacity(0.9); // Color negro si y es 0
                }
              },
              tooltipRoundedRadius: 8,
              getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
                return lineBarsSpot.map((lineBarSpot) {
                  return LineTooltipItem(
                    lineBarSpot.y.abs().toString(), // Valor absoluto de "y"
                    const TextStyle(
                      color: Color(0xff2d0079),
                      fontFamily: "SequelSans",
                    ),
                  );
                }).toList();
              },
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 0,
                color: Color(0xff6200ff).withOpacity(0.6),
                strokeWidth: 2,
                dashArray: [5, 5],
              ),
            ],
          ),
        ),
      ),
    );

  }


  void reinicializarShowingTooltipOnSpots() {
    showingTooltipSpot=-1;
    showingTooltipOnSpots = [];
    _selected=false;
    _fetchSituacionFinal2();
    print(_selected);
  }

  Future<List<List<dynamic>>> getChampionMatchesForPlayer(String playerName, String champion) async {
    List<List<dynamic>> championMatchesList = [];
    List<List<dynamic>> championMatchesList2 = [];

    var series = await FirebaseFirestore.instance
        .collection('competition')
        .doc("lec_2023_3")
        .collection('series')
        .orderBy("hora",descending: true)
        .get();

    for (var serieDoc in series.docs) {
      final competitionDoc = await serieDoc.reference.parent.parent?.get();
      var partidosQuery = await FirebaseFirestore.instance
          .collection('competition')
          .doc("lec_2023_3")
          .collection('series')
          .doc(serieDoc.id)
          .collection('partido')
          .where("acabado", isEqualTo: true)
          .get();

      for (var partidoDoc in partidosQuery.docs) {
        var data = partidoDoc.data();
        var jugadoresAzul = List<String>.from(data['jugadores_azul'] ?? []);
        var champsAzul = List<String>.from(data['champs_azul'] ?? []);
        var jugadoresRojo = List<String>.from(data['jugadores_rojo'] ?? []);
        var champsRojo = List<String>.from(data['champs_rojo'] ?? []);

        var situacionPartidaRef = FirebaseFirestore.instance
            .collection('competition')
            .doc("lec_2023_3")
            .collection('series')
            .doc(serieDoc.id)
            .collection('partido')
            .doc(partidoDoc.id)
            .collection('situacion_partida')
            .doc("spfinal");

        var situacionPartidaSnapshot = await situacionPartidaRef.get();

        if (situacionPartidaSnapshot.exists) {
          var kdaAzul = situacionPartidaSnapshot.data()?['kda_azul'] ?? [];

          for (var i = 0; i < jugadoresAzul.length; i++) {
            var jugador = jugadoresAzul[i];
            final playerSnapshot = await FirebaseFirestore.instance
                .collection('players_info')
                .doc(jugador)
                .get();
            var foto= playerSnapshot.data()?["foto"] ?? 'no';
            var campeones = champsAzul[i];
            var lado = data['lado_azul'];

            if (jugador == playerName && campeones == champion) {
              var kdaValue = kdaAzul.length > i ? kdaAzul[i] : null;
              championMatchesList.add([jugador, campeones, serieDoc.id, partidoDoc.id, lado, data['lado_azul'], data['lado_rojo'], data["ganador"], kdaValue, competitionDoc!.data()!["nombre"],foto]);
            } if (campeones == champion) {
              var kdaValue = kdaAzul.length > i ? kdaAzul[i] : null;
              championMatchesList2.add([jugador, campeones, serieDoc.id, partidoDoc.id, lado, data['lado_azul'], data['lado_rojo'], data["ganador"], kdaValue, competitionDoc!.data()!["nombre"],foto]);
            }
          }
        }
        var kdaRojo = situacionPartidaSnapshot.data()?['kda_rojo'] ?? [];
        for (var i = 0; i < jugadoresRojo.length; i++) {
          var jugador = jugadoresRojo[i];
          final playerSnapshot = await FirebaseFirestore.instance
              .collection('players_info')
              .doc(jugador)
              .get();
          var foto= playerSnapshot.data()?["foto"] ?? 'no';
          var campeones = champsRojo[i];
          var lado = data['lado_rojo'];

          if (jugador == playerName && campeones == champion) {
            var kdaValue = kdaRojo.length > i ? kdaRojo[i] : null; // No hay datos de kda para el lado rojo
            championMatchesList.add([jugador, campeones, serieDoc.id, partidoDoc.id, lado, data['lado_azul'], data['lado_rojo'], data["ganador"], kdaValue, competitionDoc!.data()!["nombre"],foto]);
          }  if (campeones == champion) {
            var kdaValue = kdaRojo.length > i ? kdaRojo[i] : null;
            championMatchesList2.add([jugador, campeones, serieDoc.id, partidoDoc.id, lado, data['lado_azul'], data['lado_rojo'], data["ganador"], kdaValue, competitionDoc!.data()!["nombre"],foto]);
          }
        }
      }
    }

    // Devolver solo los últimos 5 elementos de cada lista
    if (championMatchesList.length > 5) {
      championMatchesList = championMatchesList.sublist(championMatchesList.length - 5);
    }
    if (championMatchesList2.length > 5) {
      championMatchesList2 = championMatchesList2.sublist(championMatchesList2.length - 5);
    }
    return [championMatchesList, championMatchesList2];
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



  void _navigateToTextScreen(String equipo, String jugador, String champ, String minions, String kda, String minuto, String runa) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50), // Bordes redondeados
          ),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(height: 20,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 65.0,
                          height: 65.0,
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
                              width: 65.0,
                              height: 65.0,
                              child: ClipOval(
                                child: FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('players_info')
                                      .doc(jugador)
                                      .get(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    }
                                    final foto = snapshot.data!['foto'];
                                    return Image.network(
                                      foto,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -10,
                          bottom: 0,
                          child: Container(
                            width: 35.0,
                            height: 35.0,
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
                                width: 30.0,
                                height: 30.0,
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/${equipo.toLowerCase()}.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 30,),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 65.0,
                          height: 65.0,
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
                              width: 65.0,
                              height: 65.0,
                              child: ClipOval(
                                child: Image.network(
                                  "https://ddragon.leagueoflegends.com/cdn/14.10.1/img/champion/${champ}.png",
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (runa.isNotEmpty)
                          Positioned(
                            right: -10,
                            bottom: 0,
                            child: Container(
                              width: 35.0,
                              height: 35.0,
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
                                  width: 30.0,
                                  height: 30.0,
                                  child: ClipOval(
                                    child: FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('players_info')
                                          .doc(jugador)
                                          .get(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return CircularProgressIndicator();
                                        }

                                        final dicc = {
                                          "Domination": ["DarkHarvest", "HailOfBlades", "Predator"],
                                          "Inspiration": ["FirstStrike", "GlacialAugment", "UnsealedSpellbook"],
                                          "Precision": ["Conqueror", "LethalTempo", "PressTheAttack", "FleetFootwork"],
                                          "Resolve": ["GraspOfTheUndying", "Guardian", "VeteranAftershock"],
                                          "Sorcery": ["ArcaneComet", "PhaseRush", "SummonAery"],
                                        };
                                        String categoria = dicc.entries.firstWhere((entry) => entry.value.contains(runa)).key;
                                        String imageUrl = "https://ddragon.leagueoflegends.com/cdn/img/perk-images/Styles/$categoria/$runa/${runa}${runa == 'LethalTempo' ? 'Temp' : ''}.png";

                                        return Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20,),
                Text(
                  "${jugador} - ${champ}",
                  style: TextStyle(fontSize: 20.0, fontFamily: "Sequel100", color: Color(0xff6200ff)),
                ),
                SizedBox(height: 5,),
                Text(
                  kda,
                  style: TextStyle(fontSize: 24.0,fontFamily: "SequelSans", color: Color(0xff6200ff)),
                ),
                Text(
                  "${minions} CS   ${(int.parse(minions) / int.parse(minuto)).toStringAsFixed(1)} CS/M",
                  style: TextStyle(fontSize: 20.0,fontFamily: "SequelSans", color: Color(0xff6200ff)),
                ),
                FutureBuilder(
                  future: getChampionMatchesForPlayer(jugador, champ),
                  builder: (BuildContext context, AsyncSnapshot<List<List<dynamic>>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator(); // Indicador de carga
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (snapshot.hasData) {
                      List<dynamic> championMatchesList = snapshot.data![0];
                      List<dynamic> championMatchesList2 = snapshot.data![1];
                      return Column(
                        children: [
                          SizedBox(height: 18,),
                          Text(
                            "Ultimos partidos de ${jugador} con ${champ}",
                            textAlign: TextAlign.center,
                            // Aquí se añade el texto "texto"
                            style: TextStyle(
                              fontFamily: "Sequel100",
                              color: Color(0xff6200ff),

                            ),//
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: ClampingScrollPhysics(),
                            itemCount: championMatchesList.length,
                            itemBuilder: (BuildContext context, int index) {
                              return ListTile(
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Ganador
                                    Container(
                                      width: 30,  // Ajusta el ancho según sea necesario
                                      height: 30, // Ajusta la altura según sea necesario
                                      color: championMatchesList[index][5] == championMatchesList[index][7] ? Color(0xff04e2bc) : Color(0xffe2046c),
                                      child: Center(
                                        child: Text(
                                          championMatchesList[index][5] == championMatchesList[index][7] ? 'W': "L",
                                          style: TextStyle(
                                              color: Colors.white, // Color del texto "W"
                                              fontWeight: FontWeight.bold,
                                              fontFamily: "SequelSans"
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 18.0), // Espacio entre el ganador y el resto del texto
                                    // Equipos y mapa
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                '${championMatchesList[index][5]}',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(
                                                  fontSize: 15.0,
                                                  fontFamily: "Sequel100",
                                                  color: Color(0xff6200ff),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              Image.asset(
                                                'assets/${championMatchesList[index][5].toLowerCase()}.png',
                                                width: 30,
                                                height: 30,
                                              ),
                                              SizedBox(width: 20),
                                              Text(
                                                '-',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 17.0,
                                                  fontFamily: "Sequel100",
                                                  color: Color(0xff6200ff),
                                                ),
                                              ),
                                              SizedBox(width: 20),
                                              Image.asset(
                                                'assets/${championMatchesList[index][6].toLowerCase()}.png',
                                                width: 30,
                                                height: 30,
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                '${championMatchesList[index][6]}',
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
                                            '${championMatchesList[index][9]}',
                                            style: TextStyle(
                                              fontSize: 12.0,
                                              fontFamily: "SequelSans",
                                              color: Color(0xff6200ff),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 18.0),
                                    // Campeón y KDA
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${championMatchesList[index][8]}',
                                          style: TextStyle(
                                            color: Color(0xff6200ff), // Color del texto "W"
                                            fontFamily: "SequelSans",
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                //subtitle: Text("${championMatchesList[index][1]},${championMatchesList[index][8]},${championMatchesList[index][9]} "),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PartidoDetailPage(
                                        id: championMatchesList[index][3],
                                        competition_id: widget.competition_id,
                                        equipo1: championMatchesList[index][5],
                                        equipo2: championMatchesList[index][6],
                                        serie_id: championMatchesList[index][2],
                                      ),
                                    ),
                                  );
                                },
                              );

                            },
                          ),
                          SizedBox(height: 18,),
                          Text(
                            "Ultimos partidos con ${champ}",
                            style: TextStyle(
                              fontFamily: "Sequel100",
                              color: Color(0xff6200ff),
                            ),// Aquí se añade el texto "texto"
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: ClampingScrollPhysics(),
                            itemCount: championMatchesList2.length,
                            itemBuilder: (BuildContext context, int index) {
                              return ListTile(
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Ganador
                                    Container(
                                      width: 30,  // Ajusta el ancho según sea necesario
                                      height: 30, // Ajusta la altura según sea necesario
                                      color: championMatchesList2[index][5] == championMatchesList2[index][7]
                                          ? Color(0xff04e2bc)
                                          : Color(0xffe2046c),
                                      child: Center(
                                        child: Text(
                                          championMatchesList2[index][5] == championMatchesList2[index][7] ? 'W' : 'L',
                                          style: TextStyle(
                                            color: Colors.white, // Color del texto "W"
                                            fontWeight: FontWeight.bold,
                                            fontFamily: "SequelSans",
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 5.0), // Espacio entre el ganador y el resto del texto

                                    Column(
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
                                                  championMatchesList2[index][10],
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${championMatchesList2[index][0]}',
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontSize: 8.0,
                                            fontFamily: "SequelSans",
                                            color: Color(0xff6200ff),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 5.0),
                                    // Equipos y mapa
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                '${championMatchesList2[index][5]}',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(
                                                  fontSize: 15.0,
                                                  fontFamily: "Sequel100",
                                                  color: Color(0xff6200ff),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              Image.asset(
                                                'assets/${championMatchesList2[index][5].toLowerCase()}.png',
                                                width: 30,
                                                height: 30,
                                              ),
                                              SizedBox(width: 15),
                                              Text(
                                                '-',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 17.0,
                                                  fontFamily: "Sequel100",
                                                  color: Color(0xff6200ff),
                                                ),
                                              ),
                                              SizedBox(width: 15),
                                              Image.asset(
                                                'assets/${championMatchesList2[index][6].toLowerCase()}.png',
                                                width: 30,
                                                height: 30,
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                '${championMatchesList2[index][6]}',
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
                                            '${championMatchesList2[index][9]}',
                                            style: TextStyle(
                                              fontSize: 12.0,
                                              fontFamily: "SequelSans",
                                              color: Color(0xff6200ff),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 10.0),
                                    // Campeón y KDA
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${championMatchesList2[index][8]}',
                                          style: TextStyle(
                                            color: Color(0xff6200ff), // Color del texto "W"
                                            fontFamily: "SequelSans",
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PartidoDetailPage(
                                        id: championMatchesList2[index][3],
                                        competition_id: widget.competition_id,
                                        equipo1: championMatchesList2[index][5],
                                        equipo2: championMatchesList2[index][6],
                                        serie_id: championMatchesList2[index][2],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      );
                    } else {
                      return Text('No se encontraron datos');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }











}