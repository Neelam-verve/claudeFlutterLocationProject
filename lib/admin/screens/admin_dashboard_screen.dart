import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/models/user_model.dart';
import '../../shared/routes/app_routes.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.put(AdminController());
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      drawer: const AppDrawer(role: 'admin'),
      body: Obx(() {
        if (controller.users.isEmpty) {
          return const Center(child: Text('No users found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.users.length,
          itemBuilder: (context, index) {
            final UserModel user = controller.users[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(user.name.isNotEmpty
                      ? user.name[0].toUpperCase()
                      : '?'),
                ),
                title: Text(user.name.isNotEmpty ? user.name : 'Unnamed'),
                subtitle: Text(user.email),
                trailing: user.latitude != null
                    ? const Icon(Icons.location_on, color: Colors.green)
                    : const Icon(Icons.location_off, color: Colors.grey),
                onTap: () =>
                    Get.toNamed(AppRoutes.userDetail, arguments: user),
              ),
            );
          },
        );
      }),
    );
  }
}
