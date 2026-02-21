import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import '../widgets/avatar.dart';
import '../resources/app_strings.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String? chatName;
  final String? chatAvatarBase64;

  const ChatScreen({
    super.key,
    this.chatId,
    this.chatName,
    this.chatAvatarBase64,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  final String plannerUid = "kXRLRDETdeU5v7maxsakYSp3twM2";
  final String llamaUid = "U5QQtnodR3Ufunw4OIm3BFbV6XN2";

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    if (widget.chatId != null) {
      Future.microtask(() =>
          Provider.of<ChatProvider>(context, listen: false).initMessagesStream(widget.chatId!)
      );
    }
  }

  void _onTextChanged() {
    String text = _messageController.text;
    String? template;

    if (text.endsWith('/task ')) {
      template = "Назва:\nОпис:\nПроект:\nДедлайн:";
    } else if (text.endsWith('/meet ')) {
      template = "Назва:\nОпис:\nЛокація/посилання:\nЧас:";
    }

    if (template != null) {
      String newText = text.substring(0, text.length - 6) + template;
      _messageController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  DateTime? _parseDeadline(String text) {
    try {
      final RegExp regExp = RegExp(r"(?:Дедлайн|Час):\s*(\d{2}\.\d{2}\.\d{4}(?:\s\d{2}:\d{2})?)", caseSensitive: false);
      final match = regExp.firstMatch(text);

      if (match != null && match.group(1) != null) {
        String dateStr = match.group(1)!.trim();
        if (dateStr.length == 10) {
          final parts = dateStr.split('.');
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        } else if (dateStr.length >= 16) {
          final parts = dateStr.split(' ');
          final dateParts = parts[0].split('.');
          final timeParts = parts[1].split(':');
          return DateTime(
            int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]),
            int.parse(timeParts[0]), int.parse(timeParts[1]),
          );
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || widget.chatId == null) return;

    await FirebaseAnalytics.instance.logEvent(name: 'send_message', parameters: {'length': text.length, 'screen': 'chat_screen'});

    // Перевіряє чи це чат з Ламою
    bool isLlama = widget.chatName == "Llama" || widget.chatId == llamaUid;

    context.read<ChatProvider>().sendMessage(
        widget.chatId!,
        text,
        isLlamaChat: isLlama
    );

    _messageController.clear();
  }

  @override
  void dispose() {
    // Очищує сесію AI при виході з чату
    Future.microtask(() {
      if (mounted) {
        context.read<ChatProvider>().clearAiSession();
      }
    });
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.chatName ?? 'Чат';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            if (widget.chatAvatarBase64 != null && widget.chatAvatarBase64!.isNotEmpty)
              CircleAvatar(radius: 20, backgroundImage: MemoryImage(base64Decode(widget.chatAvatarBase64!)))
            else
              Avatar(text: displayName.isNotEmpty ? displayName[0] : '?', size: 40),

            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: const TextStyle(fontSize: 16)),
                const Text('online', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoadingMessages) return const Center(child: CircularProgressIndicator());

                  var displayMessages = List.from(provider.currentMessages);

                  if (widget.chatName == "Planner" || widget.chatId == plannerUid) {
                    displayMessages.sort((a, b) {
                      DateTime dateA = _parseDeadline(a.text) ?? a.timestamp.toDate();
                      DateTime dateB = _parseDeadline(b.text) ?? b.timestamp.toDate();
                      return dateA.compareTo(dateB);
                    });
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(15),
                    itemCount: displayMessages.length + (provider.isAiTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (provider.isAiTyping && index == 0) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F1F1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Text("Llama думає...",
                                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                          ),
                        );
                      }

                      final msgIndex = provider.isAiTyping ? index - 1 : index;
                      final msg = displayMessages[msgIndex];
                      final isMe = msg.senderId == myUid;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF0088CC) : const Color(0xFFF1F1F1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(msg.text, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                              const SizedBox(height: 2),
                              Text("${msg.timestamp.toDate().hour}:${msg.timestamp.toDate().minute.toString().padLeft(2, '0')}",
                                  style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          decoration: InputDecoration(
                              hintText: AppStrings.messagePlaceholder,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                          )
                      )
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                      backgroundColor: const Color(0xFF0088CC),
                      child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage
                      )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}