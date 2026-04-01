import 'package:get/get.dart';
import '../../shared/controllers/auth_controller.dart';
import '../../shared/controllers/location_controller.dart';

class UserController extends GetxController {
  final AuthController _authController = Get.find();
  final LocationController _locationController = Get.find();

  @override
  void onInit() {
    super.onInit();
    final uid = _authController.currentUser.value?.uid;
    if (uid != null) {
      _locationController.startTracking(uid);
    }
  }

  @override
  void onClose() {
    _locationController.stopTracking();
    super.onClose();
  }
}
