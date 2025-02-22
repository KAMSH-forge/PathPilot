import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:http/http.dart' as http;

class OsmMapPage extends StatefulWidget {
  const OsmMapPage({super.key});

  @override
  _OsmMapPageState createState() => _OsmMapPageState();
}

class _OsmMapPageState extends State<OsmMapPage> {
  late MapController _mapController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapController = MapController.withUserPosition(
      trackUserLocation: UserTrackingOption(
        enableTracking: true,
      ),
    );
    _zoomToCurrentLocation();
  }

  Future<void> _zoomToCurrentLocation() async {
    try {
      await _mapController.currentLocation();
      GeoPoint location = await _mapController.myLocation();
      await _mapController.goToLocation(location);
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  /// Searches for the location using the Nominatim API.
  Future<List<GeoPoint>> _searchLocationFromNominatim(String query) async {
    final url =
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        return [GeoPoint(latitude: lat, longitude: lon)];
      }
    }
    return [];
  }

  Future<void> _searchLocation() async {
    String query = _searchController.text;
    if (query.isNotEmpty) {
      try {
        List<GeoPoint> results = await _searchLocationFromNominatim(query);
        if (results.isNotEmpty) {
          GeoPoint newLocation = results.first;
          await _mapController.goToLocation(newLocation);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Location not found")),
          );
        }
      } catch (e) {
        print("Search error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('OSM Map with Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search location...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchLocation,
                ),
              ],
            ),
          ),
          Expanded(
            child: OSMFlutter(
              controller: _mapController,
              osmOption: OSMOption(
                userTrackingOption: UserTrackingOption(
                  enableTracking: true,
                ),
                zoomOption: ZoomOption(
                  initZoom: 14,
                  minZoomLevel: 2,
                  maxZoomLevel: 18,
                ),
                showZoomController: true,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _zoomToCurrentLocation,
        child: Icon(Icons.my_location),
      ),
    );
  }
}
