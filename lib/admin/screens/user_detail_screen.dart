import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../shared/models/user_model.dart';
import '../../firebase/firestore_service.dart';
import '../../shared/controllers/audio_controller.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late final UserModel user;
  late final FirestoreService firestoreService;
  late final AudioController audioController;
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is UserModel) {
      user = args;
    } else {
      user = UserModel(uid: '', email: '', name: '', role: 'user');
    }
    firestoreService = Get.find();
    audioController = Get.find();
  }

  @override
  void dispose() {
    try {
      audioController.autoStopIfListening();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (user.uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Detail')),
        body: const Center(child: Text('Invalid user data')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name.isNotEmpty ? user.name : 'User Detail'),
      ),
      body: StreamBuilder<UserModel?>(
        stream: firestoreService.watchUser(user.uid),
        builder: (context, snapshot) {
          final liveUser = snapshot.data ?? user;
          // Auto-move camera when live location updates
          if (liveUser.latitude != null &&
              liveUser.longitude != null &&
              mapController != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              mapController?.animateCamera(
                CameraUpdate.newLatLng(
                  LatLng(liveUser.latitude!, liveUser.longitude!),
                ),
              );
            });
          }
          return Column(
            children: [
              _InfoCard(user: liveUser),
              // Start/Stop Listening button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: Obx(
                    () => ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            audioController.isCurrentlyListening.value
                            ? Colors.red
                            : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(
                        audioController.isCurrentlyListening.value
                            ? Icons.mic_off
                            : Icons.mic,
                      ),
                      label: Text(
                        audioController.isCurrentlyListening.value
                            ? 'Stop Listening'
                            : 'Start Listening',
                      ),
                      onPressed: () {
                        if (audioController.isCurrentlyListening.value) {
                          audioController.stopListeningToChild(liveUser.uid);
                        } else {
                          audioController.startListeningToChild(liveUser.uid);
                        }
                      },
                    ),
                  ),
                ),
              ),
              Obx(
                () => audioController.isCurrentlyListening.value
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hearing, color: Colors.red, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Live audio active',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 8),
              if (liveUser.latitude != null && liveUser.longitude != null)
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(liveUser.latitude!, liveUser.longitude!),
                      zoom: 15,
                    ),
                    onMapCreated: (controller) => mapController = controller,
                    markers: {
                      Marker(
                        markerId: MarkerId(liveUser.uid),
                        position: LatLng(
                          liveUser.latitude!,
                          liveUser.longitude!,
                        ),
                        infoWindow: InfoWindow(title: liveUser.name),
                      ),
                    },
                  ),
                )
              else
                const Expanded(
                  child: Center(child: Text('No location data available')),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            final freshUser = await firestoreService.getUser(user.uid);
            if (!mounted) return;
            if (freshUser != null &&
                freshUser.latitude != null &&
                freshUser.longitude != null) {
              mapController?.animateCamera(
                CameraUpdate.newLatLng(
                  LatLng(freshUser.latitude!, freshUser.longitude!),
                ),
              );
              Get.snackbar(
                'Refreshed',
                'Location: ${freshUser.latitude!.toStringAsFixed(5)}, ${freshUser.longitude!.toStringAsFixed(5)}',
              );
            } else {
              Get.snackbar('No Data', 'No updated location available');
            }
          } catch (_) {}
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final UserModel user;
  const _InfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name.isNotEmpty ? user.name : 'No Name',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Email: ${user.email}'),
            if (user.latitude != null)
              Text(
                'Location: ${user.latitude!.toStringAsFixed(5)}, ${user.longitude!.toStringAsFixed(5)}',
              ),
            if (user.lastSeen != null)
              Text('Last seen: ${user.lastSeen!.toLocal()}'),
          ],
        ),
      ),
    );
  }
}
