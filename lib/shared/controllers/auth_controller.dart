import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../firebase/auth_service.dart';
import '../../firebase/firestore_service.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find();
  final FirestoreService _firestoreService = Get.find();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  StreamSubscription<User?>? _authSubscription;

  @override
  void onInit() {
    super.onInit();
    _authSubscription = _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    // Wait until GetMaterialApp is ready for navigation
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      return Get.context == null;
    });

    if (firebaseUser == null) {
      currentUser.value = null;
      Get.offAllNamed(AppRoutes.userLogin);
      return;
    }
    final user = await _firestoreService.getUser(firebaseUser.uid);
    currentUser.value = user;
    if (user != null) {
      _navigateByRole(user.role);
    } else {
      Get.offAllNamed(AppRoutes.userLogin);
    }
  }

  void _navigateByRole(String role) {
    if (role == 'admin') {
      Get.offAllNamed(AppRoutes.adminDashboard);
    } else {
      Get.offAllNamed(AppRoutes.userDashboard);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final credential = await _authService.signUp(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        errorMessage.value = 'Sign up failed';
        return;
      }
      final uid = credential.user!.uid;
      final newUser = UserModel(
        uid: uid,
        email: email,
        name: name,
        role: role,
      );
      await _firestoreService.createUser(newUser);
      currentUser.value = newUser;
      _navigateByRole(role);
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? 'Sign up failed';
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
    required String role,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final credential = await _authService.signIn(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        errorMessage.value = 'Sign in failed';
        return;
      }
      final uid = credential.user!.uid;
      final existing = await _firestoreService.getUser(uid);
      if (existing == null) {
        errorMessage.value = 'Account not found. Please sign up first.';
        await _authService.signOut();
        return;
      }
      if (existing.role != role) {
        errorMessage.value =
            'This account is registered as ${existing.role}. Use the correct login.';
        await _authService.signOut();
        return;
      }
      currentUser.value = existing;
      _navigateByRole(existing.role);
    } on FirebaseAuthException catch (e) {
      errorMessage.value = e.message ?? 'Sign in failed';
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    currentUser.value = null;
    Get.offAllNamed(AppRoutes.userLogin);
  }
}
