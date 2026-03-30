 import 'package:cloud_firestore/cloud_firestore.dart';

class WashroomLocation {
  final String id;
  final String name;
  final double lat;
  final double long;
  final double rating;
  final String review;
  final bool isAccessible;
  final bool isGenderNeutral;
  final bool isSingleStall;

  const WashroomLocation({
    required this.id,
    required this.name,
    required this.lat,
    required this.long,
    required this.rating,
    required this.review,
    this.isAccessible = false,
    this.isGenderNeutral = false,
    this.isSingleStall = false,
  });

  //factory constructor returns an instance of the class
  //documentsnapshot is the actual document object from firestore database
  factory WashroomLocation.fromFirestore(DocumentSnapshot doc) {
    //tells compiler that the object recieved is a map of string and dynamic values 
    final data = doc.data() as Map<String, dynamic>;
    return WashroomLocation(
      id: doc.id,
      //feilds from the databse are casted to the correct type
      name: data['name'] as String,
      lat: (data['lat'] as num).toDouble(),
      long: (data['long'] as num).toDouble(),
      rating: (data['rating'] as num).toDouble(),
      review: data['review'] as String,
      //?? allows the value to be null, if its null then its automatically set to false 
      isAccessible: data['isAccessible'] as bool? ?? false,
      isGenderNeutral: data['isGenderNeutral'] as bool? ?? false,
      isSingleStall: data['isSingleStall'] as bool? ?? false,
    );
  }

  /// writes back to firestore (allows u to add new bathrooms)
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'lat': lat,
      'long': long,
      'rating': rating,
      'review': review,
      'isAccessible': isAccessible,
      'isGenderNeutral': isGenderNeutral,
      'isSingleStall': isSingleStall,
    };
  }
}
 
