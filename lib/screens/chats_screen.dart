import 'dart:convert'; // Для Base64
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/avatar.dart';
import '../resources/app_strings.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});
  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<ChatProvider>(context, listen: false).initChatsStream()
    );
  }

  void _showCreateChatDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новий чат'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(hintText: 'Введіть email', labelText: 'Email'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              final error = await context.read<ChatProvider>().createChatByEmail(email);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(error ?? 'Чат створено!'),
                  backgroundColor: error == null ? Colors.green : Colors.red,
                ));
              }
            },
            child: const Text('Створити'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.chatsTitle),
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () => Navigator.pushNamed(context, '/profile')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => context.read<ChatProvider>().searchChats(value),
              decoration: InputDecoration(
                hintText: AppStrings.searchPlaceholder,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                filled: true, fillColor: const Color(0xFFF1F1F1),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingChats) return const Center(child: CircularProgressIndicator());
                if (provider.chatsError != null) return Center(child: Text(provider.chatsError!));
                if (provider.chats.isEmpty) return const Center(child: Text('Чатів немає'));

                return ListView.builder(
                  itemCount: provider.chats.length,
                  itemBuilder: (context, index) {
                    final chat = provider.chats[index];

                    // --- ЛОГІКА ВИЗНАЧЕННЯ СПІВРОЗМОВНИКА ---
                    String chatName = 'Чат';
                    String? chatAvatarBase64; // Аватар співрозмовника

                    if (myEmail != null && chat.userEmails.contains(myEmail)) {
                      final otherIndex = chat.userEmails.indexOf(myEmail) == 0 ? 1 : 0;
                      if (otherIndex < chat.userNames.length) {
                        chatName = chat.userNames[otherIndex];
                      }
                      if (otherIndex < chat.userAvatars.length) {
                        chatAvatarBase64 = chat.userAvatars[otherIndex];
                      }
                    }

                    return ListTile(
                      // Якщо є фото (Base64) - показує його, інакше - літери
                      leading: (chatAvatarBase64 != null && chatAvatarBase64.isNotEmpty)
                          ? CircleAvatar(radius: 25, backgroundImage: MemoryImage(base64Decode(chatAvatarBase64)))
                          : Avatar(text: chatName.isNotEmpty ? chatName[0] : '?', size: 50),

                      title: Text(chatName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(chat.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF666666))),
                      trailing: Text("${chat.lastTime.toDate().hour}:${chat.lastTime.toDate().minute.toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 12)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatId: chat.id,
                              chatName: chatName,
                              chatAvatarBase64: chatAvatarBase64,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0088CC),
        onPressed: _showCreateChatDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}