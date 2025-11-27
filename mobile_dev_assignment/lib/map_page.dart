import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}


class _MapPageState extends State<MapPage> {
  late MapController _mapController;
  final TextEditingController _controller = TextEditingController();
  final Map<String, LatLng> _locations = {
    'pav': LatLng(43.9434,-78.8987),
    'sci': LatLng(43.9446,-78.8965),
    'bit': LatLng(43.9453,-78.8962),
    'erc': LatLng(43.9458,-78.8964),
    'sha': LatLng(43.9463,-78.8966),
    'lib': LatLng(43.9460,-78.8975),
    'eng': LatLng(43.9460,-78.8985),
    'sir': LatLng(43.9480,-78.8990),
  };

  final List<Marker> _markers = [];

  void _handleInput(String value) {
    final keyword = value.toLowerCase().trim();
    if (_locations.containsKey(keyword)) {
      final LatLng target = _locations[keyword]!;

      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            point: target,
            child: Icon(Icons.location_on, color: Colors.red, size: 40),
          ),
        );
      });

      // Move camera to the new marker
      _mapController.move(target, 17.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unknown keyword: $keyword')),
      );
    }
    _controller.clear();
  }



  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _goToLibrary() {
    _mapController.move(LatLng(43.9452769,-78.8963984), 17.0);
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter location keyword',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _handleInput, // triggers when user presses Enter
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(43.9452769, -78.8963984),
                initialZoom: 15.2,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=hyjNg0StqpggSG6ZeRBZ',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),
        ],
      ),

    floatingActionButton: FloatingActionButton(
      onPressed: _goToLibrary,
      child: const Icon(Icons.local_library),
    ),
  );
}
}