import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';
import '../services/groq_service.dart';

class ChatProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final GroqService _groqService = GroqService();

  final String llamaUid = "U5QQtnodR3Ufunw4OIm3BFbV6XN2";

  List<Map<String, String>> _aiSessionHistory = [];

  // --- ЧАТИ ---
  List<Chat> _chats = [];
  bool _isLoadingChats = true;
  String? _chatsError;
  String _searchQuery = '';

  StreamSubscription? _chatsSubscription;

  List<Chat> get chats {
    if (_searchQuery.isEmpty) {
      return _chats;
    } else {
      return _chats.where((chat) {
        final emails = chat.userEmails.join(' ').toLowerCase();
        return emails.contains(_searchQuery.toLowerCase());
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

  void initChatsStream() {
    _isLoadingChats = true;
    notifyListeners();

    _chatsSubscription?.cancel();
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

  // Очищення сесії AI
  void clearAiSession() {
    _aiSessionHistory = [];
    print("AI Session cleared");
  }

  bool _isAiTyping = false;
  bool get isAiTyping => _isAiTyping;

  Future<void> sendMessage(String chatId, String text, {bool isLlamaChat = false}) async {
    if (text.isEmpty) return;
    try {
      await _firestoreService.sendMessage(chatId, text);

      if (isLlamaChat) {
        _isAiTyping = true;
        notifyListeners();

        _aiSessionHistory.add({"role": "user", "content": text});
        final aiResponse = await _groqService.getChatResponse(_aiSessionHistory);
        _aiSessionHistory.add({"role": "assistant", "content": aiResponse});
        await _firestoreService.sendAiMessage(chatId, aiResponse, llamaUid);

        _isAiTyping = false;
        notifyListeners();
      }
    } catch (e) {
      _isAiTyping = false;
      notifyListeners();
      print('Error: $e');
    }
  }

  Future<String?> createChatByEmail(String email) async {
    try {
      final user = await _firestoreService.getUserByEmail(email);
      if (user == null) {
        return 'Користувача з таким email не знайдено';
      }
      return await _firestoreService.createChat(user);
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