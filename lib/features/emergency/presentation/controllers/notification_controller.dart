import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/network/supabase_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';

class NotificationController extends StateNotifier<List<Map<String, dynamic>>> {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final SupabaseClient _supabase;
  final Ref _ref;
  RealtimeChannel? _realtimeChannel;

  NotificationController(this._supabase, this._ref) : super([]) {
    _init();
  }

  void _init() async {
    try {
      // 1. Request Push notification permissions
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // 2. Initial token sync if authenticated
      final authState = _ref.read(authControllerProvider);
      if (authState is Authenticated) {
        await syncFcmToken(authState.profile.id);
        _listenToRealtimeNotifications(authState.profile.id);
      }
    } catch (_) {}

    // 3. Listen to authentication changes to sync tokens on login
    _ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next is Authenticated) {
        syncFcmToken(next.profile.id);
        _listenToRealtimeNotifications(next.profile.id);
      } else {
        _cleanup();
      }
    });

    // 4. Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground FCM: ${message.notification?.title}');
    });
  }

  Future<void> syncFcmToken(String firebaseUid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _supabase.from('profiles').update({'fcm_token': token}).eq('id', firebaseUid);
        debugPrint('FCM Token synchronized: $token');
      }
    } catch (e) {
      debugPrint('Error syncing FCM Token: $e');
    }
  }

  void _listenToRealtimeNotifications(String userId) {
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
    }

    _realtimeChannel = _supabase
        .channel('public:notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isNotEmpty) {
              state = [record, ...state];
              _showForegroundAlert(record);
            }
          },
        )
        .subscribe();

    _fetchPastNotifications(userId);
  }

  Future<void> _fetchPastNotifications(String userId) async {
    try {
      final list = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);
      state = List<Map<String, dynamic>>.from(list);
    } catch (_) {}
  }

  void _showForegroundAlert(Map<String, dynamic> notification) {
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification['title'] as String? ?? 'Alert Notification',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(notification['body'] as String? ?? ''),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'DISMISS',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase.from('notifications').update({'is_read': true}).eq('id', notificationId);
      state = state.map((item) {
        if (item['id'] == notificationId) {
          return {...item, 'is_read': true};
        }
        return item;
      }).toList();
    } catch (_) {}
  }

  void _cleanup() {
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
    state = [];
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}

final notificationControllerProvider =
    StateNotifierProvider.autoDispose<NotificationController, List<Map<String, dynamic>>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return NotificationController(supabase, ref);
});
