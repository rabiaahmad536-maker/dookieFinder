import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'review_model.dart';


class ReviewService{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _washrooms => _firestore.collection('washrooms');

  Stream<List<ReviewModel>> getReviews(String bathroomId){
    return _washrooms
        .doc(bathroomId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReviewModel.fromDoc(doc)).toList());
  }

  Future<void> addReview({
    required String bathroomId,
    required double rating,
    required String comment,
  })async{
    final user = _auth.currentUser;
    if(user == null){
      throw Exception('Login required');
    }
    await _washrooms.doc(bathroomId).collection('reviews').add({
      'userId': user.uid,
      'userEmail': user.email ?? '',
      'userName': (user.email ?? 'Anonymous').split('@').first,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _updateBathroomSummary(bathroomId);

  }

  Future<void> _updateBathroomSummary(String bathroomId) async {
    final snapshot = await _washrooms.doc(bathroomId).collection('reviews').get();

    final docs = snapshot.docs;
    if(docs.isEmpty){
      await _washrooms.doc(bathroomId).update({
        'rating': 0.0,
        'reviewCount': 0,
      });
      return;
    }

    double total = 0;
    for(final doc in docs){
      total += (doc.data()['rating'] ?? 0).toDouble();
    }

    final averageRating = total / docs.length;

    await _washrooms.doc(bathroomId).update({
      'rating': averageRating, 
      'reviewCount' : docs.length,
    });
  }
}