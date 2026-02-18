import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../services/chat_gemini_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatGeminiService _chatService = ChatGeminiService();

  // State
  List<ChatSession> _sessions = [];
  String? _currentSessionId;
  List<ChatMessage> _messages = []; // Current active messages
  bool _isLoading = false;

  // Getters
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  List<ChatSession> get sessions => _sessions;
  String? get currentSessionId => _currentSessionId;

  ChatProvider() {
    loadHistory();
  }

  // Generate a simple ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void startNewChat() {
    // If current chat is empty, don't create another new one, just stay.
    if (_messages.isEmpty && _currentSessionId != null) return;

    _currentSessionId = _generateId();
    _messages = [];
    notifyListeners();
  }

  void switchSession(String sessionId) {
    if (_currentSessionId == sessionId) return;

    final session = _sessions.firstWhere((s) => s.id == sessionId,
        orElse: () =>
            ChatSession(id: 'temp', messages: [], lastActive: DateTime.now()));

    if (session.id != 'temp') {
      _currentSessionId = session.id;
      _messages = List.from(session.messages); // Copy
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? historyJson = prefs.getStringList('chat_sessions');

    if (historyJson != null) {
      _sessions = historyJson
          .map((str) => ChatSession.fromJson(jsonDecode(str)))
          .toList();

      // Sort by last active (newest first)
      _sessions.sort((a, b) => b.lastActive.compareTo(a.lastActive));

      if (_sessions.isNotEmpty) {
        // Load the most recent session
        final mostRecent = _sessions.first;
        _currentSessionId = mostRecent.id;
        _messages = List.from(mostRecent.messages);
      } else {
        startNewChat();
      }
      notifyListeners();
    } else {
      startNewChat();
    }
  }

  Future<void> saveHistory() async {
    if (_currentSessionId == null) return;

    final prefs = await SharedPreferences.getInstance();

    // Update or Add current session
    final currentSessionIndex =
        _sessions.indexWhere((s) => s.id == _currentSessionId);

    final updatedSession = ChatSession(
      id: _currentSessionId!,
      messages: List.from(_messages),
      lastActive: DateTime.now(),
    );

    if (currentSessionIndex >= 0) {
      _sessions[currentSessionIndex] = updatedSession;
    } else {
      if (_messages.isNotEmpty) {
        _sessions.insert(0, updatedSession);
      }
    }

    // Sort again to be safe
    _sessions.sort((a, b) => b.lastActive.compareTo(a.lastActive));

    // Keep only last 5 sessions
    if (_sessions.length > 5) {
      _sessions = _sessions.sublist(0, 5);
      // If current session was removed (unlikely as it's just updated to now), handle it?
      // Since it's sorted by lastActive, current is always at top (index 0).
    }

    final List<String> historyJson =
        _sessions.map((s) => jsonEncode(s.toJson())).toList();

    await prefs.setStringList('chat_sessions', historyJson);
  }

  Future<String?> sendMessage(String text) async {
    if (text.trim().isEmpty) return null;

    final userMsg =
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now());

    _messages.add(userMsg);
    _isLoading = true;
    notifyListeners();

    // Save immediately so state isn't lost if crash
    await saveHistory();

    // Prepare history for context
    final historyMap = _messages
        .take(_messages.length - 1)
        .map((m) => {'role': m.isUser ? 'User' : 'Bot', 'text': m.text})
        .toList();

    final recentHistory = historyMap.length > 4
        ? historyMap.sublist(historyMap.length - 4)
        : historyMap;

    try {
      final responseData = await _chatService.sendMessage(text, recentHistory);

      String? targetPage = responseData['target_page'];
      if (['HELP', 'NONE'].contains(targetPage)) {
        targetPage = null;
      }
      // PROFILE is allowed as a button target if desired, or handle logic here.

      final botMsg = ChatMessage(
        text: responseData['response_message'] ?? "I didn't get that.",
        isUser: false,
        timestamp: DateTime.now(),
        targetPage: targetPage,
      );

      _messages.add(botMsg);
      _isLoading = false;
      notifyListeners();

      await saveHistory();

      return responseData['target_page'];
    } catch (e) {
      _messages.add(ChatMessage(
        text: "Error: ${e.toString()}",
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = false;
      notifyListeners();
      await saveHistory();
      return null;
    }
  }

  void deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);

    if (_currentSessionId == sessionId) {
      _messages = [];
      _currentSessionId = null;
      if (_sessions.isNotEmpty) {
        // Switch to the most recent one remaining
        final next = _sessions.first;
        _currentSessionId = next.id;
        _messages = List.from(next.messages);
      } else {
        // No sessions left, start new
        startNewChat();
      }
    }

    await saveHistory(); // Make sure to save the deletion
    notifyListeners();
  }

  void clearHelper() async {
    // Deprecated or can be used to "Delete All"
    _sessions.clear();
    _messages.clear();
    startNewChat();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_sessions');
    notifyListeners();
  }
}
