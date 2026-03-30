import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/washroom_data.dart';
 
class WashroomService {
  //actual connection to firebase database. 'bathrooms' is the name of the collection. private. 
  final _collection = FirebaseFirestore.instance.collection('washrooms');
 
  Future<List<WashroomLocation>> getWashrooms() async {
    //.get() requests the info from firebase, stores the result in snapshot.
    final snapshot = await _collection.get();
    //snapshot.docs is a list of all the documents in the collection
    return snapshot.docs
        //converts the document to a washroom object, constructor is in washroom_data.dart
        .map((doc) => WashroomLocation.fromFirestore(doc))
        //converts to list type, easier to use
        .toList();
  }
 
  //stream allows a live update from the firebase data
  Stream<List<WashroomLocation>> watchWashrooms() {
    //firestores built in time-listener, returns a new snapshot every time data changes
    return _collection.snapshots().map(
          (snapshot) => snapshot.docs
              //transforms the snapshot/updated data into the washroom object
              .map((doc) => WashroomLocation.fromFirestore(doc))
              .toList(),
        );
  }
}
 