import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> userIds;
  final List<String> userNames;
  final List<String> userEmails;
  final List<String?> userAvatars;
  final String lastMessage;
  final Timestamp lastTime;

  Chat({
    required this.id,
    required this.userIds,
    required this.userNames,
    required this.userEmails,
    required this.userAvatars,
    required this.lastMessage,
    required this.lastTime,
  });

  factory Chat.fromMap(String id, Map<String, dynamic> map) {
    var avatars = map['userAvatars'];
    List<String?> parsedAvatars = [];

    if (avatars != null) {
      parsedAvatars = List<String?>.from(avatars);
    } else {
      parsedAvatars = List.filled( (map['userIds'] as List).length, null);
    }

    return Chat(
      id: id,
      userIds: List<String>.from(map['userIds'] ?? []),
      userNames: List<String>.from(map['userNames'] ?? []),
      userEmails: List<String>.from(map['userEmails'] ?? []),
      userAvatars: parsedAvatars,
      lastMessage: map['lastMessage'] ?? '',
      lastTime: map['lastTime'] ?? Timestamp.now(),
    );
  }
}