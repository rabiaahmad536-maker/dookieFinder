import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/filter_drawer.dart';
import 'package:dookifinder/data/washroom_data.dart';

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

  Set<Marker> _buildMarkers(){
    return washroomLocations.map((washroom){
      return Marker(
        markerId: MarkerId(washroom.id),
        position: LatLng(washroom.lat, washroom.long),
        onTap: (){
          _showWashroomReview(
            name: washroom.name,
            review: washroom.review,
            rating: washroom.rating,
          );
        },
        );
    }).toSet();
  }

  void _showWashroomReview({
    required String name,
    required String review,
    required double rating,
  }){
    showModalBottomSheet(
      context: context,
      builder: (context){
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Rating: $rating/5'),
              const SizedBox(height: 12),
              Text(review),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //map extends behind the navigation bar 
      extendBodyBehindAppBar: true,  

      appBar: AppBar(
        //lets the hamburger menu icon be visible on the map
        backgroundColor: Colors.transparent,  
        elevation: 0, 
        iconTheme: const IconThemeData(                        
          color: Colors.black,                
        ),
      ),

      //menubar
      drawer: const FilterDrawer(),

      //GoogleMap is a widget from the google_maps_flutter package
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        onMapCreated: (GoogleMapController controller) {
          //assigning control of the map to an accessible variable - _mapController
          _mapController = controller;
        },
        myLocationEnabled: _locationPermissionGranted, //shows users current location
        myLocationButtonEnabled: _locationPermissionGranted, //button to center map around user location
        markers: _buildMarkers(),
      ),

    );
  }
}