import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../firebase/firestore_service.dart';
import '../../shared/controllers/auth_controller.dart';

class UserEditProfileScreen extends StatefulWidget {
  const UserEditProfileScreen({super.key});

  @override
  State<UserEditProfileScreen> createState() => _UserEditProfileScreenState();
}

class _UserEditProfileScreenState extends State<UserEditProfileScreen> {
  final _nameController = TextEditingController();
  final AuthController _authController = Get.find();
  final FirestoreService _firestoreService = Get.find();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _authController.currentUser.value?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final uid = _authController.currentUser.value?.uid;
    if (uid == null) return;
    await _firestoreService.updateUser(uid, {'name': _nameController.text.trim()});
    final updated = await _firestoreService.getUser(uid);
    _authController.currentUser.value = updated;
    setState(() => _saving = false);
    Get.back();
    Get.snackbar('Success', 'Profile updated');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
