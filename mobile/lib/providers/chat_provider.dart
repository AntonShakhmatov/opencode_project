import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  final SocketService _socketService;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _newMessageSub;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ChatProvider(this._socketService);

  Future<void> loadMessages(String jobId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '/messages/job/$jobId',
        token: token,
      );
      final data = response['data'] ?? response;
      if (data is List) {
        _messages = data
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList();
      } else {
        _error = 'Failed to load messages';
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void listenForMessages(String jobId) {
    _newMessageSub?.cancel();
    _newMessageSub = null;

    _socketService.on('newMessage', (data) {
      if (data is Map<String, dynamic> && data['jobId'] == jobId) {
        final msg = ChatMessage.fromJson(data);
        if (!_messages.any((m) => m.id == msg.id)) {
          _messages.add(msg);
          notifyListeners();
        }
      }
    });
  }

  void stopListening() {
    _newMessageSub?.cancel();
    _newMessageSub = null;
  }

  void sendMessage({
    required String jobId,
    required String senderId,
    required String content,
  }) {
    _socketService.sendMessage(
      jobId: jobId,
      senderId: senderId,
      content: content,
    );
  }
}
