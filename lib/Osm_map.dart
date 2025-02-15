import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class OsmMapPage extends StatefulWidget {
  @override
  _OsmMapPageState createState() => _OsmMapPageState();
}

class _OsmMapPageState extends State<OsmMapPage> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController(
      initPosition: GeoPoint(
        latitude: 37.0, // Default latitude
        longitude: -122.0, // Default longitude
      ),
      areaLimit: BoundingBox(
        north: 37.0,
        south: -37.0,
        east: 122.0,
        west: -122.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OSMFlutter(
        controller: _mapController,
        osmOption: OSMOption(
          userTrackingOption: UserTrackingOption(
            enableTracking: true, // Enable user location tracking
          ),
          zoomOption: ZoomOption(
            initZoom: 10, // Initial zoom level
            minZoomLevel: 2, // Minimum zoom level
            maxZoomLevel: 18, // Maximum zoom level
          ),
          showZoomController: true, // Show zoom controls
        ),
      ),
    );
  }
}