import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

//class that holds the logic for MapScreen. Private.
class _MapScreenState extends State<MapScreen> {
  // variable that holds reference to the map. Can be null initially.
  GoogleMapController? _mapController;

  //location is not turned on until user gives permission 
  bool _locationPermissionGranted = false;

  // UoG coordinates for the map (static - belongs to class)
  static const LatLng _universityOfGuelph = LatLng(43.5314, -80.2272);

  // Initial camera position when map loads
  static const CameraPosition _initialPosition = CameraPosition(
    target: _universityOfGuelph,
    zoom: 17, //controls how close the zoom-in is
    bearing: -45, //controls angle of map
  );

  //runs once when the widget is created to request perimission for location
  @override
  void initState() {
    super.initState();
    checkLocationPermission();
  }

  //runs asyncronously hence Future<void>
  Future<void> checkLocationPermission() async {
  LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      setState(() {
        _locationPermissionGranted = true;
      });
    }
    //create else statement - what does app do if permission is denied??????
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('DookiFinder'),
      ),

      //GoogleMap is a widget from the google_maps_flutter package
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        onMapCreated: (GoogleMapController controller) {
          //assigning control of the map to an accessible variable - _mapController
          _mapController = controller;
        },
        myLocationEnabled: _locationPermissionGranted, //shows users current location
        myLocationButtonEnabled: _locationPermissionGranted, //button to center map around user location
      ),

    );
  }
}