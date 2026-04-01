import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class LocationFirebaseService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> updateLocation({
    required String uid,
    required double latitude,
    required double longitude,
  }) async {
    await _db.collection('users').doc(uid).update({
      'latitude': latitude,
      'longitude': longitude,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}
