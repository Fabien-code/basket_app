import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; 
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(ShotTrackerApp());
}

class ShotTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CourtScreen(),
    );
  }
}

class CourtScreen extends StatefulWidget {
  @override
  _CourtScreenState createState() => _CourtScreenState();
}

class _CourtScreenState extends State<CourtScreen> {
  List<Spot> spots = [];
  Map<int, List<ShotRecord>> spotRecords = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Charger les données enregistrées
void _loadData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // Charger les spots sauvegardés
  String? savedSpots = prefs.getString('spots');
  if (savedSpots != null) {
    setState(() {
      spots = (json.decode(savedSpots) as List).map((item) => Spot.fromJson(item)).toList();
    });
  }

  // Charger les enregistrements de tirs
  String? savedData = prefs.getString('spotRecords');
  if (savedData != null) {
    setState(() {
      spotRecords = (json.decode(savedData) as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          int.parse(key),
          (value as List).map((item) => ShotRecord.fromJson(item)).toList(),
        ),
      );
    });
  }
}
void _saveSpots() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String jsonData = json.encode(spots.map((spot) => spot.toJson()).toList());
  await prefs.setString('spots', jsonData);
}


  void _editSpotName(int index) {
  TextEditingController nameController = TextEditingController(text: spots[index].name);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Éditer le nom du spot'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'Nom du spot'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                spots[index].name = nameController.text;
              });
              _saveSpots(); // Sauvegarder le nom modifié
              Navigator.of(context).pop();
            },
            child: Text('Enregistrer'),
          ),
        ],
      );
    },
  );
}


  // Sauvegarder les données localement
  void _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonData = json.encode(spotRecords.map((key, value) => MapEntry(
        key.toString(), value.map((item) => item.toJson()).toList())));
    await prefs.setString('spotRecords', jsonData);
  }

  // Ajouter un spot à l'endroit cliqué
void _addSpot(Offset position) {
  setState(() {
    spots.add(Spot(position: position));
  });
  _saveSpots(); // Sauvegarder les spots après l'ajout
}


  // Enregistrer un tir marqué ou raté pour un spot
  void _recordShot(int spotIndex, int madeShots, int missedShots) {
    setState(() {
      if (!spotRecords.containsKey(spotIndex)) {
        spotRecords[spotIndex] = [];
      }
      spotRecords[spotIndex]!.add(ShotRecord(
        madeShots: madeShots,
        missedShots: missedShots,
        date: DateTime.now(),
      ));
    });
    _saveData();
  }
  
  void _clearData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('spotRecords'); // Supprime les données sauvegardées
  setState(() {
    spots.clear();        // Vider les spots affichés
    spotRecords.clear();  // Vider les enregistrements de tirs
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Basketball Shot Tracker'),
         actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () {
              // Naviguer vers StatsScreen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StatsScreen(spotRecords: spotRecords)),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete), // Icône de suppression
            onPressed: _clearData,    // Appeler la méthode pour supprimer les données
          ),
        ],
      ),
      body: GestureDetector(
        onTapUp: (details) {
          _addSpot(details.localPosition);
        },
        child: Stack(
          children: [
            // Image du demi-terrain
            Positioned.fill(
              child: Image.asset('assets/half_court.png', fit: BoxFit.cover),
            ),
            // Afficher les spots ajoutés
            ...spots.asMap().entries.map((entry) {
              int index = entry.key;
              Spot spot = entry.value;
              return Positioned(
                left: spot.position.dx - 20,
                top: spot.position.dy - 20,
                child: GestureDetector(
                  onTap: () {
                    _showShotInputDialog(context, index);
                  },
                  onLongPress: () {
                    _editSpotName(index); // Permettre l'édition du nom sur un long press
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.circle,
                        color: Colors.red,
                        size: 40,
                      ),
                      Text(spot.name), // Afficher le nom du spot
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Afficher une boîte de dialogue pour saisir les tirs
  void _showShotInputDialog(BuildContext context, int spotIndex) {
    int madeShots = 0;
    int missedShots = 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Saisir les tirs pour le spot ${spotIndex + 1}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Tirs marqués'),
                onChanged: (value) {
                  madeShots = int.tryParse(value) ?? 0;
                },
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Tirs ratés'),
                onChanged: (value) {
                  missedShots = int.tryParse(value) ?? 0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                _recordShot(spotIndex, madeShots, missedShots);
                Navigator.of(context).pop();
              },
              child: Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }
}

// Classe représentant un spot
class Spot {
  final Offset position;
  String name;

  Spot({required this.position, this.name = 'Spot'});

  // Convertir en JSON pour sauvegarde
  Map<String, dynamic> toJson() => {
        'dx': position.dx,
        'dy': position.dy,
        'name': name,
      };

  // Convertir de JSON pour chargement
  static Spot fromJson(Map<String, dynamic> json) {
    return Spot(
      position: Offset(json['dx'], json['dy']),
      name: json['name'],
    );
  }
}



class StatsScreen extends StatelessWidget {
  final Map<int, List<ShotRecord>> spotRecords;

  StatsScreen({required this.spotRecords});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistiques des Tirs par Spot'),
      ),
      body: ListView(
        children: spotRecords.entries.map((entry) {
          int spotIndex = entry.key;
          List<ShotRecord> records = entry.value;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Column(
                children: [
                  Text('Spot ${spotIndex + 1}', style: TextStyle(fontSize: 20)),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      _buildChartData(records),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Fonction pour construire les données du graphique
  LineChartData _buildChartData(List<ShotRecord> records) {
    List<FlSpot> spots = [];
    double minX = double.infinity, maxX = double.negativeInfinity;

    // Convertir les enregistrements en points de tir
    for (var i = 0; i < records.length; i++) {
      ShotRecord record = records[i];
      double x = record.date.millisecondsSinceEpoch.toDouble(); // Convertir la date en double pour l'axe des x
      double y = (record.madeShots / (record.madeShots + record.missedShots)) * 100; // Calculer le pourcentage de réussite

      spots.add(FlSpot(x, y));
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
    }

    return LineChartData(
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              // Formater les dates pour l'axe des x
              DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return Text(DateFormat('dd/MM').format(date));
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true),
        ),
      ),
      borderData: FlBorderData(show: true),
      minX: minX,
      maxX: maxX,
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 2,
          color: Colors.blue,
          dotData: FlDotData(show: true),
        ),
      ],
    );
  }
}


// Classe représentant un enregistrement de tirs
class ShotRecord {
  final int madeShots;
  final int missedShots;
  final DateTime date;

  ShotRecord({
    required this.madeShots,
    required this.missedShots,
    required this.date,
  });

  // Convertir en JSON pour sauvegarde
  Map<String, dynamic> toJson() => {
        'madeShots': madeShots,
        'missedShots': missedShots,
        'date': date.toIso8601String(),
      };

  // Convertir de JSON pour chargement
  static ShotRecord fromJson(Map<String, dynamic> json) {
    return ShotRecord(
      madeShots: json['madeShots'],
      missedShots: json['missedShots'],
      date: DateTime.parse(json['date']),
    );
  }
}
