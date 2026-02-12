import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_storage.dart';

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
  static const String baseUrl = 'https://naylinhtet.me/api';

  static Future<List<ChatRoom>> getChatRooms() async {
    final token = AuthStorage.getAuthHeader();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/chat/rooms'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('Chat rooms response: $data');
      final rooms = (data['rooms'] as List? ?? [])
          .map((e) => ChatRoom.fromJson(e))
          .toList();
      debugPrint('Parsed ${rooms.length} chat rooms');
      return rooms;
    } else {
      debugPrint('Chat rooms error: ${response.statusCode} - ${response.body}');
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to fetch chat rooms');
    }
  }

  static Future<List<ChatMessage>> getMessages(String roomId) async {
    final token = AuthStorage.getAuthHeader();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/chat/rooms/$roomId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final messages = (data['messages'] as List? ?? [])
          .map((e) => ChatMessage.fromJson(e))
          .toList();
      return messages;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to fetch messages');
    }
  }

  static Future<ChatMessage> sendMessage(String roomId, String content) async {
    final token = AuthStorage.getAuthHeader();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/chat/rooms/$roomId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return ChatMessage.fromJson(data['message'] ?? data);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to send message');
    }
  }
}
