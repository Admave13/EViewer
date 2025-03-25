import 'package:flutter/material.dart';

class PlayerDetailPage extends StatefulWidget {
  final String ign;

  PlayerDetailPage({required this.ign});

  @override
  _PlayerDetailPageState createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends State<PlayerDetailPage> {
  late bool _loadingPlayer = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Detalles de Jugador"),
        ),
        body: _loadingPlayer
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height / 8,
              alignment: Alignment.center,
              child: Text(
                widget.ign,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: DefaultTabController(
                length: 4,
                child: Scaffold(
                  appBar: AppBar(
                    automaticallyImplyLeading: false,
                    bottom: TabBar(
                      isScrollable: true,
                      labelPadding:
                      EdgeInsets.symmetric(horizontal: 16.0),
                      tabs: [
                        Tab(text: 'Resumen'),
                        Tab(text: 'Series'),
                        Tab(text: 'Trayectoria'),
                        Tab(text: 'Compañeros'),
                      ],
                    ),
                  ),
                  body: TabBarView(
                    children: [
                      Container(
                        child: Center(
                          child: Text(
                              'Contenido de la pestaña "Series"'),
                        ),
                      ),
                      Container(
                        child: Center(
                          child: Text(
                              'Contenido de la pestaña "Series"'),
                        ),
                      ),
                      Container(
                        child: Center(
                          child: Text(
                              'Contenido de la pestaña "Trayectoria"'),
                        ),
                      ),
                      Container(
                        child: Center(
                          child: Text(
                              'Contenido de la pestaña "Compañeros"'),
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