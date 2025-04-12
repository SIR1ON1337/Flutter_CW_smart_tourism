import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../dev/map_dev/marker_info.dart';
import '../dev/map_dev/search.dart';

void initFirebase() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

class MapScreen extends StatefulWidget {
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  List<Marker> _markers = [];
  LatLng _currentPosition = LatLng(42.983100, 47.504745);
  bool _isLocationAvailable = false;//переменные

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _mapController = MapController();
    _getCurrentLocation();

  } //Инициализация компонентов

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return; // Если сервисы местоположения выключены, выходим
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        return; // Если разрешение не получено
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude); // Обновляем текущие координаты
      _isLocationAvailable = true; // Местоположение доступно
      _loadMarkers(); // Загружаем маркеры, включая текущую позицию
    });

    _mapController.move(_currentPosition, 13.0); // Перемещаем карту на текущие координаты
  } //Местоположение

  Future<void> _loadMarkers() async {
    // Получаем данные из Firestore
    final querySnapshot =
    await FirebaseFirestore.instance.collection('tour_zones').get();

    // Преобразуем их в список маркеров
    final markers = querySnapshot.docs.map((doc) {
      final data = doc.data();
      return Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(data['latitude'], data['longitude']),
        child: IconButton(onPressed: (){
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MarkerDetailsPage(
                name: data['Name'],
                description: data['Description'] ?? 'Описание отсутствует',
                photoUrl: data['PhotoUrl'] ?? '',
              ),
            ),
          );
        }, icon: Icon(Icons.location_on,color: Colors.amberAccent,size: 40.0,)),
      );
    }).toList();

    markers.add(
      Marker(
        width: 80.0,
        height: 80.0,
        point: _currentPosition, // Устанавливаем маркер на текущие координаты
        child: Icon(
          Icons.circle,
          color: Colors.blue, // Цвет маркера для текущего местоположения
          size: 20.0,
        ),
      ),
    );

    // Обновляем состояние
    setState(() {
      _markers = markers;
    });
  } //Функция добавления элементов к карте

  void _moveToZone(double latitude, double longitude) {
    setState(() {
      _currentPosition = LatLng(latitude, longitude);
    });
    _mapController.move(_currentPosition, 13.0); // Перемещаем карту
  } // Функция перемещения

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Smart Tourism",
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
        actions: [
          IconButton(onPressed: (){Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchScreen(
                onZoneSelected: _moveToZone, // функция для перемещения
              ),
            ),
          );
            } , icon: Icon(Icons.search)), // кнопка поиска по имени
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  final nameController = TextEditingController();
                  final photoUrlController = TextEditingController();
                  final descriptionController = TextEditingController();
                  final latController = TextEditingController();
                  final lonController = TextEditingController();

                  return AlertDialog(
                    title: Text('Добавить новую зону'),
                    content: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(labelText: 'Название'),
                          ),
                          TextField(
                            controller: photoUrlController,
                            decoration: InputDecoration(labelText: 'URL фотографии'),
                          ),
                          TextField(
                            controller: descriptionController,
                            decoration: InputDecoration(labelText: 'Описание'),
                          ),
                          TextField(
                            controller: latController,
                            decoration: InputDecoration(labelText: 'Широта'),
                            keyboardType: TextInputType.number,
                          ),
                          TextField(
                            controller: lonController,
                            decoration: InputDecoration(labelText: 'Долгота'),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final name = nameController.text;
                          final photoUrl = photoUrlController.text;
                          final description = descriptionController.text;
                          final lat = double.tryParse(latController.text);
                          final lon = double.tryParse(lonController.text);

                          if (name.isNotEmpty && lat != null && lon != null) {
                            await FirebaseFirestore.instance
                                .collection('tour_zones')
                                .add({
                              'Name': name,
                              'PhotoUrl': photoUrl,
                              'Description': description,
                              'latitude': lat,
                              'longitude': lon,
                            });
                            Navigator.of(context).pop();
                            _loadMarkers(); // Обновляем маркеры после добавления
                          } else {
                            // Показать сообщение об ошибке
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Заполните все поля корректно')),
                            );
                          }
                        },
                        child: Text('Сохранить'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(Icons.add_box_outlined),
          ),  // кнопка добавления элементов к бд
          IconButton(onPressed: (){
            _getCurrentLocation();
            }, icon: Icon(Icons.location_on_outlined)), //перемещение к моим координатам

        ],
        backgroundColor: Colors.amberAccent,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentPosition,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
              markers: _markers,),

        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/bot');
        },
        child: Icon(
          Icons.auto_awesome,
          color: Colors.white,
        ),
        backgroundColor: Colors.amberAccent,
      ),
    );
  }
}
