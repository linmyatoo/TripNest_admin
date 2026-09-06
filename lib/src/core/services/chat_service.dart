import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_storage.dart';
import 'session.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderEmail: json['senderEmail'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ChatRoom {
  final String id;
  final String eventTitle;
  final String? eventImageUrl;
  final int memberCount;
  final ChatMessage? lastMessage;
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    required this.eventTitle,
    this.eventImageUrl,
    required this.memberCount,
    this.lastMessage,
    required this.createdAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? '',
      eventTitle: json['eventTitle'] ?? 'Untitled Event',
      eventImageUrl: json['eventImageUrl'],
      memberCount: json['memberCount'] ?? 0,
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ChatService {
  static const String baseUrl = ApiConfig.baseUrl;

  /// Decode a JSON object body, tolerating non-JSON error pages.
  ///
  /// These endpoints are polled on a timer, so an nginx HTML 502 would
  /// otherwise raise a `FormatException` every few seconds.
  static Map<String, dynamic> _decodeOrEmpty(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  static Exception _failure(String action, http.Response response) {
    final message = _decodeOrEmpty(response)['error'];
    return Exception(message ?? '$action failed (${response.statusCode})');
  }

  static Future<List<ChatRoom>> getChatRooms() async {
    final token = AuthStorage.getAuthHeader();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await apiClient.get(
      Uri.parse('$baseUrl/chat/rooms'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final data = _decodeOrEmpty(response);
      final rooms = (data['rooms'] as List? ?? [])
          .map((e) => ChatRoom.fromJson(e))
          .toList();
      debugPrint('Parsed ${rooms.length} chat rooms');
      return rooms;
    } else {
      debugPrint('Chat rooms error: ${response.statusCode}');
      throw _failure('Fetching chat rooms', response);
    }
  }

  static Future<List<ChatMessage>> getMessages(String roomId) async {
    final token = AuthStorage.getAuthHeader();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await apiClient.get(
      Uri.parse('$baseUrl/chat/rooms/$roomId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final data = _decodeOrEmpty(response);
      final messages = (data['messages'] as List? ?? [])
          .map((e) => ChatMessage.fromJson(e))
          .toList();
      return messages;
    } else {
      throw _failure('Fetching messages', response);
    }
  }

  static Future<ChatMessage> sendMessage(String roomId, String content) async {
    final token = AuthStorage.getAuthHeader();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await apiClient.post(
      Uri.parse('$baseUrl/chat/rooms/$roomId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = _decodeOrEmpty(response);
      return ChatMessage.fromJson(data['message'] ?? data);
    } else {
      throw _failure('Sending message', response);
    }
  }
}
