import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../shared/models/user_model.dart';

class FirestoreService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _users => _db.collection('users');

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
  }

  Stream<UserModel?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  Stream<List<UserModel>> watchAllUsers() {
    return _users
        .where('role', isEqualTo: 'user')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> updateListeningStatus(
      String uid, bool isListening, String channel) async {
    await _users.doc(uid).update({
      'isListening': isListening,
      'agoraChannel': channel,
    });
  }

  Stream<bool> watchIsListening(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>;
      return data['isListening'] ?? false;
    });
  }

  Future<String> getAgoraChannel(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return '';
    final data = doc.data() as Map<String, dynamic>;
    return data['agoraChannel'] ?? '';
  }

  Future<bool> emailExists(String email) async {
    final query = await _users.where('email', isEqualTo: email).limit(1).get();
    return query.docs.isNotEmpty;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final query = await _users.where('email', isEqualTo: email).limit(1).get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
