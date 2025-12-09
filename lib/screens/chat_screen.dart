import 'dart:convert'; // Base64
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
  final String? chatAvatarBase64; // <-- Нове поле

  const ChatScreen({
    super.key,
    this.chatId,
    this.chatName,
    this.chatAvatarBase64, // <--
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final myUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (widget.chatId != null) {
      Future.microtask(() =>
          Provider.of<ChatProvider>(context, listen: false).initMessagesStream(widget.chatId!)
      );
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || widget.chatId == null) return;
    await FirebaseAnalytics.instance.logEvent(name: 'send_message', parameters: {'length': text.length, 'screen': 'chat_screen'});
    context.read<ChatProvider>().sendMessage(widget.chatId!, text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.chatName ?? 'Чат';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            // ВІДОБРАЖЕННЯ АВАТАРА В ЧАТІ
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
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingMessages) return const Center(child: CircularProgressIndicator());
                if (provider.currentMessages.isEmpty) return const Center(child: Text('Повідомлень немає.'));

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(15),
                  itemCount: provider.currentMessages.length,
                  itemBuilder: (context, index) {
                    final msg = provider.currentMessages[index];
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
                            Text("${msg.timestamp.toDate().hour}:${msg.timestamp.toDate().minute.toString().padLeft(2, '0')}", style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey)),
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
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _messageController, decoration: InputDecoration(hintText: AppStrings.messagePlaceholder, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)))),
                const SizedBox(width: 10),
                CircleAvatar(backgroundColor: const Color(0xFF0088CC), child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}