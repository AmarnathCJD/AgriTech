class ChatMessage {
  final String text; // The message content
  final bool isUser; // True if user sent, false if bot
  final DateTime timestamp; // When the message was sent

  final String? targetPage; // Optional target page for navigation

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.targetPage,
  });

  // Convert to Map for storage
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser, // Stored as isUser to match the field
      'timestamp': timestamp.toIso8601String(),
      'targetPage': targetPage,
    };
  }

  // Create from Map
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      targetPage: json['targetPage'],
    );
  }
}

class ChatSession {
  final String id;
  final List<ChatMessage> messages;
  final DateTime lastActive;

  ChatSession({
    required this.id,
    required this.messages,
    required this.lastActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messages': messages.map((m) => m.toJson()).toList(),
      'lastActive': lastActive.toIso8601String(),
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
      lastActive: DateTime.parse(json['lastActive']),
    );
  }
}
