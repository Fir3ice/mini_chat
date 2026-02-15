import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/avatar.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../resources/app_strings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // Метод для вибору та стиснення фото
  Future<void> _updateAvatar() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 200, // Стискаємо як при реєстрації
      maxHeight: 200,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64String = base64Encode(bytes);
      await _authService.updateProfile(avatarBase64: base64String);
      setState(() {}); // Перемальовуємо екран
    }
  }

  // Модалка для зміни імені або статусу
  void _showEditFieldDialog(String title, String currentValue, Function(String) onSave, {int maxLength = 50}) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        title: Text(title),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width,
          child: TextField(
            controller: controller,
            maxLength: maxLength,
            decoration: InputDecoration(hintText: "Введіть нове значення"),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              await onSave(controller.text.trim());
              if (mounted) {
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
  }

  // Шторка вибору: що саме редагуємо
  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => FutureBuilder<UserModel?>(
        future: _firestoreService.getCurrentUser(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Змінити аватар'),
                onTap: () { Navigator.pop(ctx); _updateAvatar(); },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Змінити ім\'я'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditFieldDialog('Змінити ім\'я', user?.displayName ?? '', (val) => _authService.updateProfile(name: val));
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Змінити статус'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditFieldDialog('Змінити статус', user?.status ?? '', (val) => _authService.updateProfile(status: val), maxLength: 50);
                },
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  // ДІАЛОГ ЗМІНИ ПАРОЛЯ
  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        title: const Text('Змінити пароль'),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: oldPassController, obscureText: true, decoration: const InputDecoration(labelText: 'Старий пароль')),
              const SizedBox(height: 10),
              TextField(controller: newPassController, obscureText: true, decoration: const InputDecoration(labelText: 'Новий пароль')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            onPressed: () async {
              try {
                await _authService.updatePassword(oldPassController.text, newPassController.text);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пароль успішно змінено'), backgroundColor: Colors.green));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
              }
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
  }

// ДІАЛОГ ВИДАЛЕННЯ АККАУНТА
  void _showDeleteAccountDialog() {
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        title: const Text('Видалити аккаунт?', style: TextStyle(color: Colors.red)),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Усі ваші дані будуть безповоротно видалені. Введіть пароль для підтвердження.'),
              const SizedBox(height: 10),
              TextField(controller: passController, obscureText: true, decoration: const InputDecoration(labelText: 'Пароль')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            onPressed: () async {
              try {
                await _authService.deleteUserAccount(passController.text.trim());
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
              }
            },
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
  }

// ШТОРКА КОНФІДЕНЦІЙНОСТІ
  void _showPrivacyOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Змінити пароль'),
            onTap: () { Navigator.pop(ctx); _showChangePasswordDialog(); },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Видалити аккаунт', style: TextStyle(color: Colors.red)),
            onTap: () { Navigator.pop(ctx); _showDeleteAccountDialog(); },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text(AppStrings.profileTitle),
      ),
      body: FutureBuilder<UserModel?>(
        future: _firestoreService.getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final user = snapshot.data;
          final userName = user?.displayName ?? 'Користувач';
          final userEmail = user?.email ?? 'No email';
          final userStatus = user?.status ?? 'Статус не встановлено';
          final avatarBase64 = user?.avatarBase64;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (avatarBase64 != null && avatarBase64.isNotEmpty)
                      CircleAvatar(radius: 50, backgroundImage: MemoryImage(base64Decode(avatarBase64)))
                    else
                      Avatar(text: userName.isNotEmpty ? userName[0] : '?', size: 100),
                    const SizedBox(height: 15),
                    Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    Text(userEmail, style: const TextStyle(color: Color(0xFF666666))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(userStatus, style: const TextStyle(color: Color(0xFF0088CC), fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: [
                    _buildMenuItem('Редагувати профіль', _showEditOptions),
                    _buildMenuItem('Налаштування сповіщень', () {}),
                    _buildMenuItem('Конфіденційність', _showPrivacyOptions),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () async {
                          await _authService.signOut();
                          if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        },
                        child: const Text(AppStrings.logoutButton),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(String title, VoidCallback onTap) {
    return ListTile(title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap);
  }
}