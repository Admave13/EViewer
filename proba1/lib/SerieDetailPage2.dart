import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'my_home_page.dart';



class SerieDetailScreen extends StatefulWidget {
  final SerieData serieData;

  SerieDetailScreen({required this.serieData});

  @override
  _SerieDetailScreenState createState() => _SerieDetailScreenState();
}

class _SerieDetailScreenState extends State<SerieDetailScreen> {
  late List<String> _partidoIds = [];
  late bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPartidoIds();
  }

  Future<void> _fetchPartidoIds() async {
    var partidosRef = FirebaseFirestore.instance
        .collection('competition')
        .doc(widget.serieData.competitionId)
        .collection('series')
        .doc(widget.serieData.id)
        .collection('partido')
        .get();

    var partidoSnapshot = await partidosRef;
    var partidoIds = partidoSnapshot.docs.map((doc) => doc.id).toList();

    setState(() {
      _partidoIds = partidoIds;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Detalles de la Serie'),
        ),
        body: Column(
          children: [
            // Container que muestra el equipo1 de SerieData
            Container(
              height: MediaQuery.of(context).size.height / 8,
              alignment: Alignment.center,
              child: Text(widget.serieData.equipo1),
            ),
            // Sección para las pantallas desplazables
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Scaffold(
                  appBar: AppBar(
                    automaticallyImplyLeading: false,
                    bottom: TabBar(
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
                      _loading
                          ? Center(child: CircularProgressIndicator())
                          : _partidoIds.isEmpty
                          ? Center(
                        child: Text('No hay partidos'),
                      )
                          : ListView.builder(
                        itemCount: _partidoIds.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_partidoIds[index]),
                          );
                        },
                      ),
                      Center(child: Text('Contenido de Previa')),
                      Center(child: Text('Contenido de Clasificación')),
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