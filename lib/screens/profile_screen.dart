import 'dart:convert'; // Для Base64
import 'package:flutter/material.dart';
import '../widgets/avatar.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../resources/app_strings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text(AppStrings.profileTitle),
      ),
      body: FutureBuilder<UserModel?>(
        // Завантажуємо свіжі дані з бази (статус, фото)
        future: firestoreService.getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          final userName = user?.displayName ?? authService.currentUser?.displayName ?? 'Користувач';
          final userEmail = user?.email ?? authService.currentUser?.email ?? 'No email';
          final userStatus = user?.status ?? 'Статус не встановлено';
          final avatarBase64 = user?.avatarBase64;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Логіка відображення аватара: Base64 або Ініціали
                    if (avatarBase64 != null && avatarBase64.isNotEmpty)
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: MemoryImage(base64Decode(avatarBase64)),
                      )
                    else
                      Avatar(text: userName.isNotEmpty ? userName[0] : '?', size: 100),

                    const SizedBox(height: 15),
                    Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    Text(userEmail, style: const TextStyle(color: Color(0xFF666666))),
                    const SizedBox(height: 8),
                    // Відображаємо статус
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        userStatus,
                        style: const TextStyle(color: Color(0xFF0088CC), fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: [
                    _buildMenuItem('Редагувати профіль', () {}),
                    _buildMenuItem('Налаштування сповіщень', () {}),
                    _buildMenuItem('Конфіденційність', () {}),

                    // Кнопку Crashlytics видалено, як ти і просив!

                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () async {
                          await authService.signOut();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                          }
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
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}