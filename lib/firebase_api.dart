import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Request notification permissions
    await _firebaseMessaging.requestPermission();

    // Get the device token
    final token = await _firebaseMessaging.getToken();
    print("Firebase Messaging Token: $token");

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
        'Received a foreground notification: ${message.notification?.title}',
      );
      print('Notification body: ${message.notification?.body}');

      // Display the notification details in the console
      if (message.notification != null) {
        print('Notification Title: ${message.notification!.title}');
        print('Notification Body: ${message.notification!.body}');
      }
    });
  }
}
