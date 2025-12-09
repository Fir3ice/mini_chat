import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- КОРИСТУВАЧІ ---
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final snapshot = await _db.collection('users').where('email', isEqualTo: email).limit(1).get();
    if (snapshot.docs.isNotEmpty) return UserModel.fromMap(snapshot.docs.first.data());
    return null;
  }

  // --- ЧАТИ ---
  Future<String> createChat(UserModel otherUser) async {
    final myUid = _auth.currentUser!.uid;

    final me = await getCurrentUser();

    final myName = me?.displayName ?? 'User';
    final myAvatar = me?.avatarBase64;
    final myEmail = me?.email ?? _auth.currentUser!.email!;

    // 2. Створює чат
    final chatRef = _db.collection('chats').doc();

    await chatRef.set({
      'userIds': [myUid, otherUser.uid],
      'userEmails': [myEmail, otherUser.email],
      'userNames': [myName, otherUser.displayName],
      'userAvatars': [myAvatar, otherUser.avatarBase64],
      'lastMessage': 'Чат створено',
      'lastTime': FieldValue.serverTimestamp(),
    });

    return chatRef.id;
  }

  Stream<List<Chat>> getChatsStream() {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return const Stream.empty();

    return _db
        .collection('chats')
        .where('userIds', arrayContains: myUid)
        .orderBy('lastTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Chat.fromMap(doc.id, doc.data())).toList();
    });
  }

  // --- ПОВІДОМЛЕННЯ ---
  Future<void> sendMessage(String chatId, String text) async {
    final myUid = _auth.currentUser!.uid;
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': myUid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastTime': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Message>> getMessagesStream(String chatId) {
    return _db.collection('chats').doc(chatId).collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Message.fromMap(doc.id, doc.data())).toList());
  }
}