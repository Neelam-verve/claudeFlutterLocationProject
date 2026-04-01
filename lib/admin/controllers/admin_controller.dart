import 'dart:async';

import 'package:get/get.dart';
import '../../firebase/firestore_service.dart';
import '../../shared/models/user_model.dart';

class AdminController extends GetxController {
  final FirestoreService _firestoreService = Get.find();

  final RxList<UserModel> users = <UserModel>[].obs;
  final RxBool isLoading = false.obs;

  StreamSubscription<List<UserModel>>? _usersSubscription;

  @override
  void onInit() {
    super.onInit();
    _usersSubscription = _firestoreService.watchAllUsers().listen((list) {
      users.assignAll(list);
    });
  }

  @override
  void onClose() {
    _usersSubscription?.cancel();
    super.onClose();
  }
}
