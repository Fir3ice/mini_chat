import 'dart:convert'; // Для перетворення картинки в текст (Base64)
import 'dart:io'; // Для роботи з файлом картинки
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Бібліотека для вибору фото

import '../widgets/custom_text_field.dart';
import '../widgets/avatar.dart';
import '../services/auth_service.dart';
import '../resources/app_strings.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _statusController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Змінні для фото
  File? _selectedImage;
  String? _avatarBase64;

  // Метод для вибору фото з галереї
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();

      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        // --- АГРЕСИВНЕ СТИСНЕННЯ ---
        maxWidth: 200,
        maxHeight: 200,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        // Перевіряє розмір файлу перед обробкою
        final length = await pickedFile.length();
        print('Розмір файлу: ${length / 1024} KB');

        if (length > 800 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Фото занадто велике, оберіть інше'), backgroundColor: Colors.red),
            );
          }
          return;
        }

        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);

        setState(() {
          _selectedImage = File(pickedFile.path);
          _avatarBase64 = base64String;
        });

        print('Фото успішно оброблено!');
      }
    } catch (e) {
      print('Помилка вибору фото: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Реєстрація
  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          status: _statusController.text.trim().isEmpty ? null : _statusController.text.trim(),
          avatarBase64: _avatarBase64, // Передаємо фото
        );

        if (mounted) {
          // Очищаємо стек навігації, щоб не було кнопки "Назад"
          Navigator.pushNamedAndRemoveUntil(context, '/chats', (route) => false);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // Google реєстрація
  void _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        // Очищаємо стек навігації
        Navigator.pushNamedAndRemoveUntil(context, '/chats', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text(AppStrings.registerTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- БЛОК ВИБОРУ ФОТО ---
              GestureDetector(
                onTap: _pickImage, // Клік відкриває галерею
                child: _selectedImage != null
                    ? CircleAvatar(
                  radius: 50, // size 100 / 2
                  backgroundImage: FileImage(_selectedImage!),
                )
                    : const Avatar(text: '', showPlus: true, size: 100),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedImage == null ? AppStrings.addPhoto : 'Змінити фото',
                style: const TextStyle(color: Color(0xFF666666)),
              ),
              // -------------------------

              const SizedBox(height: 30),

              CustomTextField(
                label: AppStrings.nameLabel,
                placeholder: AppStrings.namePlaceholder,
                controller: _nameController,
                validator: (val) => val!.isEmpty ? AppStrings.errorEmptyName : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: AppStrings.emailLabel,
                placeholder: AppStrings.emailPlaceholder,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                validator: (val) {
                  if (val == null || val.isEmpty) return AppStrings.errorEmptyEmail;
                  if (!val.contains('@')) return AppStrings.errorInvalidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: AppStrings.passwordLabel,
                placeholder: AppStrings.passwordPlaceholder,
                obscureText: true,
                controller: _passwordController,
                validator: (val) => (val!.length < 6) ? AppStrings.errorShortPassword : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: AppStrings.statusLabel,
                placeholder: AppStrings.statusPlaceholder,
                controller: _statusController,
                validator: (val) => (val != null && val.length > 50) ? AppStrings.errorLongStatus : null,
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(AppStrings.registerButton),
                ),
              ),

              const SizedBox(height: 20),
              const Text('АБО', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signUpWithGoogle,
                icon: const Icon(Icons.login, color: Color(0xFF0088CC)),
                label: const Text(AppStrings.googleRegisterButton),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}