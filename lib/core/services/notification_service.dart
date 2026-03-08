import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:html' as html;

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 알림 권한 요청 및 FCM 토큰 저장
  static Future<bool> initialize() async {
    try {
      if (kIsWeb) {
        return await _initializeWeb();
      } else {
        return await _initializeMobile();
      }
    } catch (e) {
      debugPrint('[NotificationService] 초기화 오류: $e');
      return false;
    }
  }

  /// 웹용 초기화
  static Future<bool> _initializeWeb() async {
    try {
      // 브라우저 알림 권한 요청
      final permission = await html.Notification.requestPermission();

      if (permission != 'granted') {
        debugPrint('[NotificationService] 웹 알림 권한이 거부되었습니다.');
        return false;
      }

      debugPrint('[NotificationService] 웹 알림 권한 승인됨');

      // Firebase Messaging 토큰 가져오기
      try {
        final token = await _messaging.getToken();
        if (token != null) {
          debugPrint('[NotificationService] FCM Token: $token');
          await _saveTokenToFirestore(token);
        }
      } catch (e) {
        debugPrint('[NotificationService] FCM 토큰 가져오기 실패 (웹): $e');
        // 웹에서 토큰 가져오기 실패해도 알림 권한은 허용됨
      }

      return true;
    } catch (e) {
      debugPrint('[NotificationService] 웹 초기화 오류: $e');
      return false;
    }
  }

  /// 모바일용 초기화
  static Future<bool> _initializeMobile() async {
    // 1. 알림 권한 요청
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('[NotificationService] 알림 권한이 거부되었습니다.');
      return false;
    }

    debugPrint('[NotificationService] 알림 권한 승인됨');

    // 2. FCM 토큰 가져오기
    final token = await _messaging.getToken();

    if (token != null) {
      debugPrint('[NotificationService] FCM Token: $token');
      await _saveTokenToFirestore(token);
    }

    // 3. 토큰 갱신 리스너
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[NotificationService] Token refreshed: $newToken');
      _saveTokenToFirestore(newToken);
    });

    // 4. 포그라운드 메시지 핸들러
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[NotificationService] 포그라운드 메시지 수신: ${message.notification?.title}');
    });

    // 5. 알림 클릭 핸들러 (앱이 백그라운드에 있을 때)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[NotificationService] 알림 클릭으로 앱 열림: ${message.data}');
    });

    return true;
  }

  /// FCM 토큰을 Firestore에 저장
  static Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[NotificationService] FCM 토큰 저장 완료');
    } catch (e) {
      debugPrint('[NotificationService] 토큰 저장 오류: $e');
    }
  }

  /// FCM 토큰 삭제 (로그아웃 시)
  static Future<void> removeToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }
      await _messaging.deleteToken();
      debugPrint('[NotificationService] FCM 토큰 삭제 완료');
    } catch (e) {
      debugPrint('[NotificationService] 토큰 삭제 오류: $e');
    }
  }

  /// 알림 권한 상태 확인
  static Future<bool> hasPermission() async {
    if (kIsWeb) {
      return html.Notification.permission == 'granted';
    } else {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }
  }
}
