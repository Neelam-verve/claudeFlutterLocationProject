import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';

class AppDrawer extends StatelessWidget {
  final String role;
  const AppDrawer({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();
    return Drawer(
      child: Obx(() {
        final user = authController.currentUser.value;
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.name ?? 'No Name'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                child: Text(
                  (user?.name.isNotEmpty == true)
                      ? user!.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Dashboard'),
              onTap: () {
                Get.back();
                if (role == 'admin') {
                  Get.offAllNamed(AppRoutes.adminDashboard);
                } else {
                  Get.offAllNamed(AppRoutes.userDashboard);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () {
                Get.back();
                if (role == 'admin') {
                  Get.toNamed(AppRoutes.adminEditProfile);
                } else {
                  Get.toNamed(AppRoutes.userEditProfile);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Get.back();
                await authController.signOut();
              },
            ),
          ],
        );
      }),
    );
  }
}
