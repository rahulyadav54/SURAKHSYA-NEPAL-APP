import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseService {
  static bool _isInitialized = false;

  FirebaseService();

  /// Safe bootstrapping logic wrapped to prevent native crashes in development
  static Future<void> initialize() async {
    try {
      // Safely attempts to hook native platform configurations
      await Firebase.initializeApp();
      _isInitialized = true;
      debugPrint('Firebase successfully initialized.');
      
      // Request FCM permissions by default
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('WARNING: Firebase initialization failed or config omitted. App will fall back gracefully. Detail: $e');
    }
  }

  /// Retrieves FCM push token for targeted emergency broadcasts
  Future<String?> getDeviceToken() async {
    if (!_isInitialized) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Error fetching FCM token: $e');
      return null;
    }
  }

  /// Sets up event listeners for active push notifications
  void setupNotificationListeners() {
    if (!_isInitialized) return;
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground push notification received: ${message.notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Background notification tapped: ${message.data}');
    });
  }
}

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});
