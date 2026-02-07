import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class SocketService {
  static SocketService? _instance;

  // Supabase Realtime Channel for THIS user
  RealtimeChannel? _myChannel;
  String? _currentUserId;
  bool _isConnecting = false;

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  // Event Listeners: Map<EventName, List<Callbacks>>
  final Map<String, List<Function(dynamic)>> _listeners = {};

  static SocketService get instance {
    _instance ??= SocketService._();
    return _instance!;
  }

  SocketService._();

  bool get isConnected => _myChannel != null;
  RealtimeChannel? get socket => _myChannel; // Backward compatibility
  Stream<bool> get connectionStream => _connectionController.stream;
  String? get currentUserId => _currentUserId;

  /// Connect to Supabase Realtime
  /// This subscribes to valid channel for receiving events targeting THIS user.
  Future<bool> connect(String userId) async {
    if (_isConnecting) return false;

    // If already connected to this user's channel
    if (_myChannel != null && _currentUserId == userId) {
      debugPrint('✅ Realtime already connected for $userId');
      return true;
    }

    if (_myChannel != null) {
      await disconnect();
    }

    _isConnecting = true;
    _currentUserId = userId;

    debugPrint('');
    debugPrint('╔══════════════════════════════════════════╗');
    debugPrint('║     🔌 CONNECTING SUPABASE REALTIME       ║');
    debugPrint('╚══════════════════════════════════════════╝');
    debugPrint('   • User ID : $userId');
    debugPrint('');

    try {
      final client = Supabase.instance.client;

      // Subscribe to my own channel to receive messages/calls
      _myChannel = client.channel('user_v1:$userId');

      _myChannel!
          .onBroadcast(
            event: '*',
            callback: (payload, [ref]) {
              _handleIncomingEvent(payload['event'], payload['payload']);
            },
          )
          .subscribe((status, error) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('✅ Subscribed to private channel: user_v1:$userId');
              _connectionController.add(true);
              _isConnecting = false;

              // Alert I am online (optional, can be expanded for Presence)
              _myChannel!.track({
                'online_at': DateTime.now().toIso8601String(),
              });
            } else if (status == RealtimeSubscribeStatus.closed) {
              debugPrint('❌ Channel closed');
              _connectionController.add(false);
              _isConnecting = false;
            }
          });

      return true;
    } catch (e) {
      debugPrint('❌ Realtime connection error: $e');
      _isConnecting = false;
      return false;
    }
  }

  /// Handle incoming broadcast events
  void _handleIncomingEvent(String? event, dynamic payload) {
    if (event == null) return;

    debugPrint('📥 Received Event: $event');
    // debugPrint('   Payload: $payload');

    if (_listeners.containsKey(event)) {
      for (var callback in _listeners[event]!) {
        try {
          callback(payload);
        } catch (e) {
          debugPrint('❌ Error in listener callback for $event: $e');
        }
      }
    }
  }

  /// Emit event to a specific target user
  /// This broadcasts to THEIR channel.
  Future<bool> emitToUser(
    String targetUserId,
    String event,
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint('📤 Emitting to user: $targetUserId | Event: $event');

      // We send to the TARGET's channel
      final targetChannel = Supabase.instance.client.channel(
        'user_v1:$targetUserId',
      );

      // We don't need to subscribe to send, but for broadcast we might need to be
      // attached. However, Supabase allows publishing to channels via client.

      // Note: triggerBroadcast sends to everyone subscribed to the channel.
      // Since the target subscribes to 'user_v1:{targetId}', we send there.

      targetChannel.subscribe();

      // Small delay to ensure connection if not exists?
      // Actually Supabase SDK usually handles this, or we can just send.
      // Ideally we use a shared persistent connection if possible, but creating
      // valid channel reference is cheap.

      // ignore: invalid_use_of_internal_member
      await targetChannel.send(
        type: 'broadcast' as dynamic,
        event: '*',
        payload: {'event': event, 'payload': data},
      );

      debugPrint('✅ Signal sent successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error emitting to user: $e');
      return false;
    }
  }

  /// Register event listener
  void on(String event, Function(dynamic) callback) {
    if (!_listeners.containsKey(event)) {
      _listeners[event] = [];
    }
    _listeners[event]!.add(callback);
    debugPrint('👂 Listening to: $event');
  }

  /// Remove event listener
  void off(String event) {
    _listeners.remove(event);
    debugPrint('🔇 Stopped listening to: $event');
  }

  /// Disconnect
  Future<void> disconnect() async {
    if (_myChannel != null) {
      debugPrint('🔌 Disconnecting Realtime...');
      await Supabase.instance.client.removeChannel(_myChannel!);
      _myChannel = null;
      _currentUserId = null;
      _isConnecting = false;
      _listeners.clear();
      debugPrint('✅ Disconnected');
    }
  }

  // Helper for CallManager backward compatibility catch
  // If consumers use `emit` without target, we log error or try to infer.
  // BUT: existing code uses `emit` which we removed.
  // We will re-add `emit` but mark it deprecated and try to handle it.
  Future<bool> emit(String event, dynamic data) async {
    debugPrint('⚠️ DEPRECATED: emit() called. Use emitToUser() instead.');
    debugPrint('   Event: $event');
    debugPrint('   Data: $data');

    // Try to infer target from data
    if (data is Map) {
      final target = data['toUserId'] ?? data['receiverId'];
      if (target != null) {
        return emitToUser(
          target.toString(),
          event,
          Map<String, dynamic>.from(data),
        );
      }
    }

    debugPrint('❌ Could not infer target user for emit()');
    return false;
  }
}
