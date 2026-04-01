import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/user_controller.dart';
import '../../shared/controllers/auth_controller.dart';
import '../../shared/controllers/location_controller.dart';
import '../../shared/widgets/app_drawer.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserController _ = Get.put(UserController(), permanent: true);
    final AuthController authController = Get.find();
    final LocationController locationController = Get.find();

    return Scaffold(
      appBar: AppBar(title: const Text('My Location')),
      drawer: const AppDrawer(role: 'user'),
      body: Obx(() {
        final position = locationController.currentPosition.value;
        final user = authController.currentUser.value;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const Icon(Icons.person),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(user?.email ?? ''),
                    ],
                  ),
                  const Spacer(),
                  Obx(() => Chip(
                        label: Text(locationController.isTracking.value
                            ? 'Tracking'
                            : 'Idle'),
                        backgroundColor: locationController.isTracking.value
                            ? Colors.green.shade100
                            : Colors.grey.shade200,
                      )),
                ],
              ),
            ),
            if (position != null)
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(position.latitude, position.longitude),
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: {
                    Marker(
                      markerId: const MarkerId('me'),
                      position: LatLng(position.latitude, position.longitude),
                      infoWindow:
                          InfoWindow(title: user?.name ?? 'My Location'),
                    ),
                  },
                ),
              )
            else
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      }),
    );
  }
}
