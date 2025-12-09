import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import '../resources/app_strings.dart'; // Підключаємо рядки

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Вхід через Email
  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Успіх -> в чати
        if (mounted) Navigator.pushReplacementNamed(context, '/chats');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // Вхід через Google
  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/chats');
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    AppStrings.appTitle,
                    style: TextStyle(fontSize: 32, color: Color(0xFF0088CC), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppStrings.appSubtitle,
                    style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 40),

                  // Email
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

                  // Пароль
                  CustomTextField(
                    label: AppStrings.passwordLabel,
                    placeholder: AppStrings.passwordPlaceholder,
                    obscureText: true,
                    controller: _passwordController,
                    validator: (val) => (val == null || val.isEmpty) ? AppStrings.errorEmptyPassword : null,
                  ),
                  const SizedBox(height: 24),

                  // Кнопка Входу
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(AppStrings.loginButton, style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Кнопка Google
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loginWithGoogle,
                    icon: const Icon(Icons.login, color: Color(0xFF0088CC)),
                    label: const Text(AppStrings.googleLoginButton),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Посилання на реєстрацію
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text(AppStrings.toRegister, style: TextStyle(color: Color(0xFF0088CC))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}