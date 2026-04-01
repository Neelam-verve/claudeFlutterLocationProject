import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../firebase/agora_service.dart';
import '../../firebase/firestore_service.dart';
import 'auth_controller.dart';

class AudioController extends GetxController {
  final FirestoreService _firestoreService = Get.find();
  final AgoraService _agoraService = Get.find();
  final AuthController _authController = Get.find();

  StreamSubscription<bool>? _listeningSubscription;
  final RxBool isCurrentlyListening = false.obs;
  String? listeningToChildUid;

  @override
  void onInit() {
    super.onInit();
    // Watch for user login/logout changes
    ever(_authController.currentUser, _onUserChanged);
    // Initialize if user is already logged in
    final user = _authController.currentUser.value;
    if (user != null && user.role == 'user') {
      _watchListeningState(user.uid);
    }
  }

  void _onUserChanged(dynamic user) {
    _listeningSubscription?.cancel();
    _listeningSubscription = null;

    if (user != null && user.role == 'user') {
      _watchListeningState(user.uid);
    } else {
      // Logged out or admin — stop broadcasting if active
      _agoraService.stopBroadcasting();
    }
  }

  /// Child side: watch own isListening field, start/stop broadcasting
  void _watchListeningState(String uid) {
    _listeningSubscription = _firestoreService.watchIsListening(uid).listen(
      (listening) async {
        if (listening && !_agoraService.isBroadcasting) {
          debugPrint('AudioController: isListening=true, starting broadcast');
          await _agoraService.startBroadcasting(uid);
        } else if (!listening && _agoraService.isBroadcasting) {
          debugPrint('AudioController: isListening=false, stopping broadcast');
          await _agoraService.stopBroadcasting();
        }
      },
      onError: (e) {
        debugPrint('AudioController: Error watching isListening: $e');
      },
    );
  }

  /// Admin side: start listening to a child's audio
  Future<void> startListeningToChild(String childUid) async {
    try {
      await _firestoreService.updateListeningStatus(childUid, true, childUid);
      await _agoraService.startListening(childUid);
      listeningToChildUid = childUid;
      isCurrentlyListening.value = true;
      debugPrint('AudioController: Admin started listening to $childUid');
    } catch (e) {
      debugPrint('AudioController: startListeningToChild failed: $e');
    }
  }

  /// Admin side: stop listening to a child's audio
  Future<void> stopListeningToChild(String childUid) async {
    try {
      await _agoraService.stopListening();
      await _firestoreService.updateListeningStatus(childUid, false, '');
    } catch (e) {
      debugPrint('AudioController: stopListeningToChild failed: $e');
    }
    listeningToChildUid = null;
    isCurrentlyListening.value = false;
    debugPrint('AudioController: Admin stopped listening to $childUid');
  }

  /// Auto-stop if admin navigates away or closes app
  Future<void> autoStopIfListening() async {
    try {
      if (isCurrentlyListening.value && listeningToChildUid != null) {
        await stopListeningToChild(listeningToChildUid!);
      }
    } catch (e) {
      debugPrint('AudioController: autoStopIfListening failed: $e');
    }
  }

  @override
  void onClose() {
    _listeningSubscription?.cancel();
    try {
      _agoraService.stopBroadcasting();
      _agoraService.stopListening();
    } catch (_) {}
    super.onClose();
  }
}
