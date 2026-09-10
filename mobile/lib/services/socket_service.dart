import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_service.dart';

typedef SocketEventHandler = void Function(dynamic data);

class SocketService extends ChangeNotifier {
  io.Socket? _socket;
  bool _connected = false;
  String? _userId;

  bool get connected => _connected;
  String? get userId => _userId;

  String get _socketUrl {
    const base = ApiService.baseUrl;
    if (!base.startsWith('http')) {
      final uri = Uri.base;
      return '${uri.scheme}://${uri.host}:${uri.port}';
    }
    return base.replaceFirst('/api', '');
  }

  void connect(String token) {
    if (_socket?.connected == true) return;
    final wsUrl = _socketUrl;

    _socket = io.io(
      wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(10)
          .build(),
    );

    _socket!.onConnect((_) {
      _connected = true;
      notifyListeners();
      debugPrint('[Socket] connected');
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      notifyListeners();
      debugPrint('[Socket] disconnected');
    });

    _socket!.onConnectError((err) {
      debugPrint('[Socket] connect_error: $err');
      _connected = false;
      notifyListeners();
    });

    _socket!.onReconnect((_) {
      _connected = true;
      notifyListeners();
      debugPrint('[Socket] reconnected');
      if (_userId != null) {
        emit('register', {'userId': _userId});
      }
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connected = false;
    _userId = null;
    notifyListeners();
  }

  void registerUser(String userId) {
    _userId = userId;
    emit('register', {'userId': userId});
  }

  void joinJob(String jobId, String userId) {
    emit('joinJob', {'jobId': jobId, 'userId': userId});
  }

  void leaveJob(String jobId) {
    emit('leaveJob', {'jobId': jobId});
  }

  void sendMessage({
    required String jobId,
    required String senderId,
    required String content,
  }) {
    emit('sendMessage', {
      'jobId': jobId,
      'senderId': senderId,
      'content': content,
    });
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void on(String event, SocketEventHandler handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }
}
