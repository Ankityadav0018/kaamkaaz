import 'package:socket_io_client/socket_io_client.dart' as io;
import '../utils/api_config.dart';
import 'logger_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  String? _currentUserId;
  Function(Map<String, dynamic>)? onNotification;

  void connect(String userId) {
    if (_socket != null && _currentUserId == userId) {
      if (_socket!.connected) {
        LoggerService.i('ℹ️ Socket already connected for user: $userId');
        return;
      }
      LoggerService.i(
          'ℹ️ Socket exists for user: $userId, current status: ${_socket!.connected ? "connected" : "connecting/disconnected"}');
    }

    LoggerService.i(
        '🔌 [Socket] Initiating connection for user: $userId to ${ApiConfig.socketUrl}');

    if (_socket != null) {
      LoggerService.i('🔌 [Socket] Disposing previous instance');
      _socket!.disconnect();
      _socket!.dispose();
    }

    _currentUserId = userId;
    _socket = io.io(
        ApiConfig.socketUrl,
        io.OptionBuilder()
            .setTransports(
                ['websocket']) // Force websocket for reliability on mobile
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(2000)
            .setReconnectionAttempts(10)
            .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      LoggerService.i('🔌 [Socket] Connected: ${_socket!.id}');
      LoggerService.i('👤 [Socket] Joining room for userId: $userId');
      _socket!.emit('join', userId);
    });

    _socket!.onDisconnect(
        (reason) => LoggerService.w('🔌 [Socket] Disconnected: $reason'));
    _socket!.onConnectError(
        (e) => LoggerService.e('❌ [Socket] Connection Error', e));
    _socket!.onReconnect((_) => LoggerService.i('🔌 [Socket] Reconnected'));
    _socket!.onError((e) => LoggerService.e('❌ [Socket] General Error', e));

    _socket!.on('notification', (data) {
      LoggerService.i('🔔 [Socket] Notification: $data');
      if (onNotification != null && data is Map) {
        onNotification!(Map<String, dynamic>.from(data));
      }
    });
  }

  void disconnect() {
    LoggerService.i('🔌 Disconnecting socket');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentUserId = null;
  }

  bool get isConnected => _socket?.connected ?? false;
  io.Socket? get socket => _socket;
}
