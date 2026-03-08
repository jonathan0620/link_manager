import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 알림 권한 요청 및 FCM 토큰 저장
  static Future<bool> initialize() async {
    try {
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
      String? token;
      if (kIsWeb) {
        // 웹에서는 VAPID 키가 필요할 수 있음
        token = await _messaging.getToken();
      } else {
        token = await _messaging.getToken();
      }

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
        // 포그라운드에서는 토스트나 다이얼로그로 알림 표시 가능
      });

      // 5. 알림 클릭 핸들러 (앱이 백그라운드에 있을 때)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[NotificationService] 알림 클릭으로 앱 열림: ${message.data}');
        // 특정 페이지로 이동 등의 처리 가능
      });

      return true;
    } catch (e) {
      debugPrint('[NotificationService] 초기화 오류: $e');
      return false;
    }
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
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}
