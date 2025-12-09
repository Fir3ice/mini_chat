abstract class AppStrings {
  // Заголовки
  static const String appTitle = 'MiniChat';
  static const String appSubtitle = 'Обмін короткими повідомленнями';
  static const String loginTitle = 'Вхід';
  static const String registerTitle = 'Реєстрація';
  static const String profileTitle = 'Мій профіль';
  static const String chatsTitle = 'Чати';

  // Поля вводу
  static const String emailLabel = 'Електронна пошта';
  static const String emailPlaceholder = 'your@email.com';
  static const String passwordLabel = 'Пароль';
  static const String passwordPlaceholder = '••••••••';
  static const String nameLabel = "Ім'я";
  static const String namePlaceholder = "Ваше ім'я";
  static const String statusLabel = 'Статус (необов’язково)';
  static const String statusPlaceholder = 'Ваш статус (макс 50)';
  static const String messagePlaceholder = 'Повідомлення...';
  static const String searchPlaceholder = 'Пошук чатів...';

  // Кнопки
  static const String loginButton = 'Увійти';
  static const String googleLoginButton = 'Увійти через Google';
  static const String googleRegisterButton = 'Зареєструватися через Google';
  static const String registerButton = 'Зареєструватися';
  static const String logoutButton = 'Вийти';
  static const String crashButton = 'Викликати Crash (Test)';
  static const String addPhoto = 'Додати фото';
  static const String toRegister = 'Зареєструватися';

  // Помилки та валідація
  static const String errorEmptyEmail = 'Введіть email';
  static const String errorInvalidEmail = 'Некоректний email';
  static const String errorEmptyPassword = 'Введіть пароль';
  static const String errorShortPassword = 'Пароль має бути > 6 символів';
  static const String errorEmptyName = "Введіть ім'я";
  static const String errorLongStatus = 'Статус має бути до 50 символів';

  const AppStrings._();
}