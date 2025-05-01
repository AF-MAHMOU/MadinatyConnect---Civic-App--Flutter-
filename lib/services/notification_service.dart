import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initializeFCM() async {
    await _fcm.requestPermission();
    String? token = await _fcm.getToken();
    print("FCM Token: $token");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received a message: ${message.notification?.title}");
    });
  }
}
