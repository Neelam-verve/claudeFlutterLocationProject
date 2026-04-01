import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../firebase/location_firebase_service.dart';

class LocationController extends GetxController {
  final LocationFirebaseService _locationService = Get.find();

  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxBool isTracking = false.obs;
  StreamSubscription<Position>? _positionStream;
  // ignore: unused_field
  String? _trackedUid;

  @override
  void onClose() {
    stopTracking();
    super.onClose();
  }

  Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<void> startTracking(String uid) async {
    final granted = await requestPermissions();
    if (!granted) {
      Get.snackbar('Permission Denied', 'Location permission is required');
      return;
    }
    _trackedUid = uid;
    isTracking.value = true;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position position) async {
      currentPosition.value = position;
      await _locationService.updateLocation(
        uid: uid,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    });
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    isTracking.value = false;
    _trackedUid = null;
  }

  Future<Position?> getCurrentPosition() async {
    final granted = await requestPermissions();
    if (!granted) return null;
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
