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
import 'package:provider/provider.dart';
import '../state/filter_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/review_model.dart';
import '../data/review_service.dart';
import 'login_page.dart';

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

  final ReviewService _reviewService = ReviewService();

  WashroomLocation _washroomFromDoc(DocumentSnapshot<Map<String, dynamic>> doc,) {
    final data = doc.data() ?? {};

    return WashroomLocation(
      id: doc.id,
      name: data['name'] ?? 'Unknown Washroom',
      lat: (data['lat'] ?? 0).toDouble(),
      long: (data['long'] ?? 0).toDouble(),
      review: data['review'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      isAccessible: data['isAccessible'] ?? false,
      isGenderNeutral: data['isGenderNeutral'] ?? false,
      isSingleStall: data['isSingleStall'] ?? false,
    );
  }

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

  Set<Marker> _buildMarkers(FilterState filters, List<WashroomLocation> firestoreWashrooms,){
    //apply filters
    final filtered = filters.applyFilters(firestoreWashrooms);

    return filtered.map((washroom){
      return Marker(
        markerId: MarkerId(washroom.id),
        position: LatLng(washroom.lat, washroom.long),
        onTap: (){
          _showWashroomReview(washroom: washroom);
        },
      );
    }).toSet();
  }

  //get nearest bathroom
  Future<WashroomLocation?> _findNearestWashroom(Position userPosition, List<WashroomLocation> firestoreWashrooms,) async {
    if (firestoreWashrooms.isEmpty) return null;
    
    WashroomLocation? nearest;

    //set to infinity to find shorter path to bathroom
    double shortestDistance = double.infinity; 
    
    //going though washroom data 
    for (var washroom in firestoreWashrooms) {
      double distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        washroom.lat,
        washroom.long,
      );
      
      //comparing prev distance to current
      if (distance < shortestDistance) {
        shortestDistance = distance;
        nearest = washroom;
      }
    }
    
    return nearest;
  }

  //when button is pressed 
  Future<void> _handleEmergency() async {
    //if locatoin is not enabled
    if (!_locationPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission required for emergency feature.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoadingDirections = true);

    try {
      // Get current position
      Position? userPosition;
      try {
        userPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        userPosition = await Geolocator.getLastKnownPosition();
      }

      if (userPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get your location. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoadingDirections = false);
        return;
      }

      //find nearest bathroom func
      final snapshot = await FirebaseFirestore.instance.collection('washrooms').get();
      final firestoreWashrooms = snapshot.docs.map((doc) => _washroomFromDoc(doc)).toList();
      WashroomLocation? nearestWashroom = await _findNearestWashroom(userPosition, firestoreWashrooms);
      
      // if nearest washroom is null before real dialogue
      if (nearestWashroom == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No bathrooms found nearby.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoadingDirections = false);
        return;
      }
      
      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Emergency Bathroom'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nearest bathroom: ${nearestWashroom.name}'),
              const SizedBox(height: 8),
              Text('Rating: ${nearestWashroom.rating}/5'),
              const Divider(),
              const Text('Get directions to this bathroom?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('GO NOW'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _getDirections(nearestWashroom, isEmergency: true);
      } 
      else {
        setState(() => _isLoadingDirections = false);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error finding nearest bathroom: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoadingDirections = false);
    }
  }


  // fetches a walking route from the user's current location to the washroom
  // and draws it as a blue line on the map
  Future<void> _getDirections(WashroomLocation washroom, {bool isEmergency = false}) async {

    print("GET DIRECTIONS FUNCTION CALLED"); //-------------------------------------------------------------------------------------------
    // Only pop if not from emergency (since emergency has no bottom sheet)
    if (!isEmergency) {
      Navigator.pop(context); 
    }

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
          print('Directions response: ${response.body}'); //-------------------------------------------------------------------------------------------
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
              color: isEmergency ? Colors.red : Colors.deepPurple, // Red for emergency, purple for regular navigation
              width: 5,
            ),
          };
          _routeDuration = duration;
        });

        //display emergency success message
        if (isEmergency) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Emergency route to ${washroom.name}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        LatLngBounds bounds = _boundsFromLatLngList([
          LatLng(userPosition.latitude, userPosition.longitude),
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

  Future <void> _showAddReviewDialog(WashroomLocation washroom) async{
    final user = FirebaseAuth.instance.currentUser;

    if(user == null){
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('Log In to write a review'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Login'),
            ),
          ],
        ),
      );

      if(shouldLogin == true && mounted){
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
      return;
    }

    final commentController = TextEditingController();
    double selectedRating = 5;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context){
        return StatefulBuilder(
          builder: (context, setDialogState){
            return AlertDialog(
              title: const Text('Write a Review'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index){
                        final starValue = index + 1;
                        return IconButton(
                          onPressed: () {
                            setDialogState((){
                              selectedRating = starValue.toDouble();
                            });
                          },
                          icon: Icon(
                            starValue <= selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Comment',
                        border: OutlineInputBorder(),
                        hintText: 'How was this washroom?'
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async{
                        final comment = commentController.text.trim();

                        if(comment.isEmpty){
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Please enter a comment.')),
                          );
                          return;
                        }

                        setDialogState((){
                          isSubmitting = true;
                        });

                    try{
                      await _reviewService.addReview(
                        bathroomId: washroom.id,
                        rating: selectedRating,
                        comment: comment,
                      );

                      if(context.mounted){
                        Navigator.pop(context);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Review Submitted')),
                        );
                      }
                    }catch(e){
                      if(context.mounted){
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text('Failed to Submit Review: $e')),
                        );
                      }

                      setDialogState((){
                        isSubmitting = false;
                      });
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text ('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // added a Get Directions button at the bottom of the sheet
  void _showWashroomReview({required WashroomLocation washroom}){
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context){
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    washroom.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('washrooms')
                        .doc(washroom.id)
                        .snapshots(),
                    builder: (context, snapshot){
                      final data = snapshot.data?.data();
                      final rating = (data?['rating'] ?? 0).toDouble();
                      final reviewCount = (data?['reviewCount'] ?? 0).toInt();

                      return Text (
                        '⭐ Rating: ${rating.toStringAsFixed(1)}/5 ($reviewCount reviews)',
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  if (washroom.isAccessible) const Text('♿ Accessible'),
                  if (washroom.isGenderNeutral) const Text('🚻 Gender Neutral'),
                  if (washroom.isSingleStall) const Text('🚪 Single Stall'),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () => _showAddReviewDialog(washroom),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Write a Review'),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Reviews',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Expanded(

                    child: StreamBuilder<List<ReviewModel>>(
                      stream: _reviewService.getReviews(washroom.id),
                      builder: (context,snapshot){
                        if(snapshot.connectionState == ConnectionState.waiting){
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if(snapshot.hasError){
                          return const Center(
                            child: Text('Failed to Load Reviews'),
                          );
                        }

                        final reviews = snapshot.data ?? [];

                        if (reviews.isEmpty) {
                          return const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No user reviews yet, be the first to leave one.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          );
                        }

                        return ListView.separated(
                          itemCount: reviews.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index){
                            final review = reviews[index];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: List.generate(5, (starIndex){
                                    return Icon(
                                      starIndex < review.rating.round()
                                        ? Icons.star
                                        : Icons.star_border,
                                      color: Colors.amber,
                                      size: 18,
                                    );
                                  }),
        
                                ),
                                const SizedBox(height: 6),
                                Text(review.comment),
                                if(review.createdAt != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${review.createdAt!.month}/${review.createdAt!.day}/${review.createdAt!.year}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

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
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        //disables the automatic menu bar, allows for a different image to be used
        automaticallyImplyLeading: false,

        //menu bar button is now an iconButton on top of white square
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),

        //adding the logo to the app bar
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(
              'assets/images/dooki_finder.png',
              height: 80,
            ),
          ),
        ],
      ),
       

      //menubar
      drawer: const FilterDrawer(),

      //GoogleMap is a widget from the google_maps_flutter package
      body: Stack(
        children: [
            Consumer<FilterState>(
              builder: (context, filters, _) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('washrooms').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final firestoreWashrooms = snapshot.data!.docs
                        .map((doc) => _washroomFromDoc(doc))
                        .toList();

                    return GoogleMap(
                      initialCameraPosition: _initialPosition,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      myLocationEnabled: _locationPermissionGranted,
                      myLocationButtonEnabled: _locationPermissionGranted,
                      markers: _buildMarkers(filters, firestoreWashrooms),
                      polylines: _polylines,
                    );
                  },
                );
              },
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
                        //if emergency mode, format directions in red
                       if (_polylines.first.color == Colors.red)
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 32,
                        )
                      else
                        const Icon(
                          Icons.directions_walk,
                          color: Colors.deepPurple,
                          size: 32,
                        ),
                      const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_polylines.first.color == Colors.red)
                              const Text(
                                'EMERGENCY - Fastest Route',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else
                              const Text(
                                'Estimated Time',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            Text(
                              _routeDuration!,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _polylines.first.color == Colors.red 
                                    ? Colors.red 
                                    : Colors.deepPurple,
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

            // emergency button formatting 
            if (_polylines.isEmpty)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton(
                    onPressed: _handleEmergency,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                      shadowColor: Colors.red.withOpacity(0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.warning_amber_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'EMERGENCY',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
  }