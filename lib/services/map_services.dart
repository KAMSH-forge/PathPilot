// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
// import 'package:location/location.dart' as loc;

// class MapService {
//   final String apiKey;

//   MapService({required this.apiKey});

//   Future<LatLng?> fetchCurrentLocation() async {
//     loc.Location location = loc.Location();
//     bool serviceEnabled = await location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await location.requestService();
//       if (!serviceEnabled) return null;
//     }

//     loc.PermissionStatus permission = await location.hasPermission();
//     if (permission == loc.PermissionStatus.denied) {
//       permission = await location.requestPermission();
//       if (permission != loc.PermissionStatus.granted) return null;
//     }

//     loc.LocationData userLocation = await location.getLocation();
//     return LatLng(userLocation.latitude!, userLocation.longitude!);
//   }

//   Future<List<LatLng>> getDirections(LatLng start, LatLng end) async {
//     final String url = "https://maps.googleapis.com/maps/api/directions/json?"
//         "origin=${start.latitude},${start.longitude}"
//         "&destination=${end.latitude},${end.longitude}"
//         "&key=$apiKey";

//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       if (data['routes'].isNotEmpty) {
//         String polyline = data['routes'][0]['overview_polyline']['points'];
//         return decodePolyline(polyline)
//             .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
//             .toList();
//       }
//     }
//     return [];
//   }

//   Future<LatLng?> searchLocation(String query) async {
//     final String url =
//         "https://maps.googleapis.com/maps/api/place/findplacefromtext/json"
//         "?input=$query&inputtype=textquery&fields=geometry&key=$apiKey";

//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       if (data["candidates"] != null &&
//           data["candidates"].isNotEmpty &&
//           data["candidates"][0]["geometry"] != null) {
//         double lat = data["candidates"][0]["geometry"]["location"]["lat"];
//         double lng = data["candidates"][0]["geometry"]["location"]["lng"];
//         return LatLng(lat, lng);
//       }
//     }
//     return null;
//   }
// }
