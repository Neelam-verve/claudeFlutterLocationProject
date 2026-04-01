import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'firebase/agora_service.dart';
import 'firebase/auth_service.dart';
import 'firebase/firestore_service.dart';
import 'firebase/location_firebase_service.dart';
import 'shared/controllers/auth_controller.dart';
import 'shared/controllers/audio_controller.dart';
import 'shared/controllers/location_controller.dart';
import 'shared/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized, skipping.');
    } else {
      rethrow; // rethrow any other real errors
    }
  }

  _registerServices();
  runApp(const MyApp());
}

void _registerServices() {
  Get.put(AuthService());
  Get.put(FirestoreService());
  Get.put(LocationFirebaseService());
  Get.put(LocationController(), permanent: true);
  Get.put(AgoraService(), permanent: true);
  Get.put(AuthController());
  Get.put(AudioController(), permanent: true);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Location App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
    );
  }
}
