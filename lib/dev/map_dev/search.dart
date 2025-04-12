import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchScreen extends StatefulWidget {
  final Function(double, double) onZoneSelected;

  SearchScreen({required this.onZoneSelected});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Map<String, dynamic>> _zones = [];
  List<Map<String, dynamic>> _filteredZones = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTourZones();
    _searchController.addListener(_filterResults); // Слушаем изменения в поиске
  }

  // Загрузка данных из Firestore
  Future<void> _loadTourZones() async {
    final querySnapshot =
    await FirebaseFirestore.instance.collection('tour_zones').get();

    final zones = querySnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();

    setState(() {
      _zones = zones;
      _filteredZones = zones; // Изначально показываем все зоны
    });
  }

  // Удаление тур-зоны
  Future<void> _deleteTourZone(String id) async {
    await FirebaseFirestore.instance.collection('tour_zones').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Тур-зона удалена')),
    );

    // Обновляем список зон после удаления
    _loadTourZones();
  }

  // Фильтрация тур-зон по имени (поиск в реальном времени)
  void _filterResults() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredZones = _zones
          .where((zone) =>
          zone['Name'].toLowerCase().contains(query)) // Поиск по имени
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterResults);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amberAccent,
        title: Text('Поиск тур-зон',
          style: TextStyle(
          color: Colors.white,
          shadows: <Shadow>[
            Shadow(
              offset: Offset(1.5, 1.5),
              blurRadius: 3.0,
              color: Colors.black,
            ),
          ],
          fontSize: 30,
        ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Введите название зоны',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: _filteredZones.isNotEmpty
                  ? ListView.builder(
                itemCount: _filteredZones.length,
                itemBuilder: (context, index) {
                  final zone = _filteredZones[index];
                  return ListTile(
                    title: Text(zone['Name']),
                    subtitle:
                    Text(zone['Description'] ?? 'Нет описания'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // Подтверждение удаления
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('Удалить тур-зону?'),
                              content: Text(
                                  'Вы уверены, что хотите удалить "${zone['Name']}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  child: Text('Отмена'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _deleteTourZone(zone['id']);
                                  },
                                  child: Text(
                                    'Удалить',
                                    style:
                                    TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    onTap: () {
                      // Передаем координаты в главный экран
                      widget.onZoneSelected(
                        zone['latitude'],
                        zone['longitude'],
                      );
                      Navigator.pop(context); // Закрываем экран поиска
                    },
                  );
                },
              )
                  : Center(child: Text('Зоны не найдены')),
            ),
          ],
        ),
      ),
    );
  }
}













