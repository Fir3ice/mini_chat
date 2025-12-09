import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';

class ChatProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // --- ЧАТИ ---
  List<Chat> _chats = [];
  bool _isLoadingChats = true; // За замовчуванням true, поки не прийдуть дані
  String? _chatsError;
  String _searchQuery = '';

  StreamSubscription? _chatsSubscription; // Підписка на оновлення

  List<Chat> get chats {
    if (_searchQuery.isEmpty) {
      return _chats;
    } else {
      return _chats.where((chat) {
        // Шукає по іменах учасників
        final names = chat.userNames.join(' ').toLowerCase();
        return names.contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  bool get isLoadingChats => _isLoadingChats;
  String? get chatsError => _chatsError;

  // --- ПОВІДОМЛЕННЯ ---
  List<Message> _currentMessages = [];
  bool _isLoadingMessages = false;
  StreamSubscription? _messagesSubscription;

  List<Message> get currentMessages => _currentMessages;
  bool get isLoadingMessages => _isLoadingMessages;

  // --- ЛОГІКА ---

  // Ініціалізація (замість loadChats)
  void initChatsStream() {
    _isLoadingChats = true;
    notifyListeners();

    _chatsSubscription?.cancel(); // Скасовує стару підписку, якщо була
    _chatsSubscription = _firestoreService.getChatsStream().listen(
          (chatsData) {
        _chats = chatsData;
        _isLoadingChats = false;
        _chatsError = null;
        notifyListeners();
      },
      onError: (error) {
        _chatsError = error.toString();
        _isLoadingChats = false;
        notifyListeners();
      },
    );
  }

  void searchChats(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Підписка на повідомлення конкретного чату
  void initMessagesStream(String chatId) {
    _isLoadingMessages = true;
    _currentMessages = [];
    notifyListeners();

    _messagesSubscription?.cancel();
    _messagesSubscription = _firestoreService.getMessagesStream(chatId).listen(
          (msgs) {
        _currentMessages = msgs;
        _isLoadingMessages = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoadingMessages = false;
        notifyListeners();
      },
    );
  }

  // Відправка
  Future<void> sendMessage(String chatId, String text) async {
    if (text.isEmpty) return;
    try {
      await _firestoreService.sendMessage(chatId, text);
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // Створення чату
  Future<String?> createChatByEmail(String email) async {
    try {
      final user = await _firestoreService.getUserByEmail(email);
      if (user == null) {
        return 'Користувача з таким email не знайдено';
      }

      // Створює чат
      await _firestoreService.createChat(user);
      return null; // Null - успіх
    } catch (e) {
      return 'Помилка створення чату: $e';
    }
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}