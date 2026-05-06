// import 'dart:async';

// // import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';

// class FcmTokenService {
//   static String _cachedToken = '';
//   static bool _initialized = false;

//   static String get currentToken => _cachedToken;

//   static Future<void> initialize() async {
//     if (_initialized) {
//       return;
//     }

//     // final messaging = FirebaseMessaging.instance;

//     await messaging.requestPermission(
//       alert: true,
//       announcement: false,
//       badge: true,
//       carPlay: false,
//       criticalAlert: false,
//       provisional: false,
//       sound: true,
//     );

//     await messaging.setAutoInitEnabled(true);

//     await fetchAndCacheToken(debugSource: 'startup');

//     FirebaseMessaging.instance.onTokenRefresh.listen((token) {
//       _cachedToken = token;
//       print('🔄 FCM token atualizado (refresh): $token');
//     });

//     _initialized = true;
//   }

//   static Future<String> fetchAndCacheToken({
//     String debugSource = 'manual',
//     Duration timeout = const Duration(seconds: 2),
//   }) async {
//     final messaging = FirebaseMessaging.instance;

//     if (!kIsWeb &&
//         (defaultTargetPlatform == TargetPlatform.iOS ||
//             defaultTargetPlatform == TargetPlatform.macOS)) {
//       try {
//         final apnsToken = await messaging.getAPNSToken();
//         print('🍎 APNS token ($debugSource): $apnsToken');
//       } catch (e) {
//         print('🍎 Erro ao ler APNS token ($debugSource): $e');
//       }
//     }

//     try {
//       final token =
//           await messaging.getToken().timeout(timeout, onTimeout: () => null);

//       _cachedToken = token ?? '';

//       print('🔔 FCM token ($debugSource): $_cachedToken');
//       if (_cachedToken.isEmpty) {
//         print('⚠️ FCM token vazio ($debugSource).');
//         if (kIsWeb) {
//           print(
//             '🌐 Web pode exigir configuração de firebase-messaging-sw.js e VAPID key para token.',
//           );
//         }
//       }

//       return _cachedToken;
//     } catch (e) {
//       print('❌ Erro ao obter FCM token ($debugSource): $e');
//       return '';
//     }
//   }

//   static Future<String> getTokenForLogin() async {
//     if (_cachedToken.isNotEmpty) {
//       print('🔔 Usando FCM token em cache no login: $_cachedToken');
//       return _cachedToken;
//     }

//     final token = await fetchAndCacheToken(
//       debugSource: 'login',
//       timeout: const Duration(milliseconds: 1200),
//     );

//     if (token.isEmpty) {
//       unawaited(_retryInBackground());
//     }

//     return token;
//   }

//   static Future<void> _retryInBackground() async {
//     for (var attempt = 0; attempt < 5; attempt++) {
//       await Future.delayed(Duration(seconds: attempt + 1));
//       final token = await fetchAndCacheToken(
//           debugSource: 'background-retry-${attempt + 1}');
//       if (token.isNotEmpty) {
//         return;
//       }
//     }
//   }
// }
