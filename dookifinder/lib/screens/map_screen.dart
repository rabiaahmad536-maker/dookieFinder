import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:dookifinder/firebase_options.dart';
import '../widgets/filter_drawer.dart';
import 'package:dookifinder/data/washroom_data.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // holds the purple route line drawn on the map, empty until user requests directions
  Set<Polyline> _polylines = {};
  // just shows a loading spinner while waiting for the directions API response
  bool _isLoadingDirections = false;
  // stores the estimated walking time to display at the bottom
  String? _routeDuration;

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
        // now passes whole washroom object instead of separate fields
        // so the directions button inside the bottom sheet can access coordinates
        onTap: () {
          _showWashroomReview(washroom: washroom);
        },
      );
    }).toSet();
  }

  // fetches a walking route from the user's current location to the washroom
  // and draws it as a blue line on the map
  Future<void> _getDirections(WashroomLocation washroom) async {
    Navigator.pop(context);

    if (!_locationPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission required for directions.')),
      );
      return;
    }

    setState(() => _isLoadingDirections = true);

    try {
      // try to get current position, timeout after 5 seconds in case GPS is slow
      Position? userPosition;
      try {
        userPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        // GPS timed out, fall back to last known location
        userPosition = await Geolocator.getLastKnownPosition();
      }

      if (userPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get your location. Try again.')),
        );
        setState(() => _isLoadingDirections = false);
        return;
      }

      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: googleMapsApiKey,
        request: PolylineRequest(
          origin: PointLatLng(userPosition.latitude, userPosition.longitude),
          destination: PointLatLng(washroom.lat, washroom.long),
          mode: TravelMode.walking,
        ),
      );

      if (result.points.isNotEmpty) {
        List<LatLng> routeCoords = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        // fetch duration separately since PolylineResult doesn't expose it
        String? duration;
        try {
          final response = await http.get(Uri.parse(
            'https://maps.googleapis.com/maps/api/directions/json'
            '?origin=${userPosition.latitude},${userPosition.longitude}'
            '&destination=${washroom.lat},${washroom.long}'
            '&mode=walking'
            '&key=$googleMapsApiKey'
          ));
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            duration = data['routes'][0]['legs'][0]['duration']['text'];
          }
        } catch (_) {
          // duration just won't show if this fails, not imporant
        }

        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: routeCoords,
              color: Colors.deepPurple,
              width: 5,
            ),
          };
          _routeDuration = duration;
        });

        LatLngBounds bounds = _boundsFromLatLngList([
          LatLng(userPosition!.latitude, userPosition.longitude),
          LatLng(washroom.lat, washroom.long),
        ]);
        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find a route. Is Directions API enabled?')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting directions: $e')),
      );
    } finally {
      setState(() => _isLoadingDirections = false);
    }
  }

  // calculates the smallest rectangle that fits both the user and destination
  // so the camera can zoom to show the whole route
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double minLat = list.first.latitude;
    double maxLat = list.first.latitude;
    double minLng = list.first.longitude;
    double maxLng = list.first.longitude;

    for (LatLng point in list) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // clears the route line from the map when user taps X in the app bar
  void _clearDirections() {
    setState(() {
      _polylines = {};
      _routeDuration = null; 
    });
  }

  // added a Get Directions button at the bottom of the sheet
  void _showWashroomReview({required WashroomLocation washroom}){
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
                washroom.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Rating: ${washroom.rating}/5'),
              const SizedBox(height: 12),
              Text(washroom.review),
              const SizedBox(height: 16),
              // button that triggers directions to this washroom
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _getDirections(washroom),
                  icon: const Icon(Icons.directions_walk),
                  label: const Text('Get Directions'),
                ),
              ),
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
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: _locationPermissionGranted,
            markers: _buildMarkers(),
            polylines: _polylines, // tells the map to draw whatever lines are in _polylines
          ),
          // loading card that overlays the map while fetching the route
          if (_isLoadingDirections)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 12),
                      Text('Finding route...'),
                    ],
                  ),
                ),
              ),
            ),
          // shows estimated walk time and exit button at the bottom when a route is active
          if (_polylines.isNotEmpty && _routeDuration != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // drag handle for visual polish
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.directions_walk, color: Colors.deepPurple, size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimated Time',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _routeDuration!,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // exit navigation button
                        ElevatedButton.icon(
                          onPressed: _clearDirections,
                          icon: const Icon(Icons.close),
                          label: const Text('Exit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}