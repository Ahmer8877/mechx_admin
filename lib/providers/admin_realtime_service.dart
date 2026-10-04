import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Keeps one Realtime connection for the whole admin dashboard.
/// Database changes trigger an immediate refresh, while a small polling
/// fallback keeps the dashboard current if the browser WebSocket is delayed.
class AdminRealtimeService {
  AdminRealtimeService._();

  static final AdminRealtimeService instance = AdminRealtimeService._();

  final StreamController<void> _changes = StreamController<void>.broadcast();
  RealtimeChannel? _channel;
  Timer? _reconnectTimer;
  bool _started = false;

  Stream<void> get changes => _changes.stream;

  void start() {
    if (_started) return;
    _started = true;
    _subscribe();
  }

  Future<void> _subscribe() async {
    final oldChannel = _channel;
    _channel = null;
    if (oldChannel != null) {
      await oldChannel.unsubscribe();
    }

    final channel = supabase.channel('mechx-admin-realtime');
    _channel = channel;

    void changed(PostgresChangePayload _) => _changes.add(null);

    channel
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'profiles',
        callback: changed,
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'bookings',
        callback: changed,
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'reviews',
        callback: changed,
      )
      ..subscribe((status, error) {
        debugPrint(
          'Admin Realtime status: $status${error == null ? '' : ' | $error'}',
        );
        if (status == RealtimeSubscribeStatus.subscribed) {
          _reconnectTimer?.cancel();
          _reconnectTimer = null;
        } else if (status == RealtimeSubscribeStatus.channelError ||
            status == RealtimeSubscribeStatus.timedOut) {
          _scheduleReconnect();
        }
      });
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive == true) return;
    _reconnectTimer = Timer(const Duration(seconds: 5), _subscribe);
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.unsubscribe();
    _channel = null;
    _changes.close();
    _started = false;
  }
}
