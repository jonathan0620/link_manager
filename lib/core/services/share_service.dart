import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  final _sharedUrlController = StreamController<String>.broadcast();
  Stream<String> get sharedUrlStream => _sharedUrlController.stream;

  StreamSubscription? _intentDataStreamSubscription;
  String? _pendingSharedUrl;

  String? get pendingSharedUrl => _pendingSharedUrl;

  void clearPendingUrl() {
    _pendingSharedUrl = null;
  }

  void initialize() {
    if (kIsWeb) return;

    // 앱이 실행 중일 때 공유받은 경우
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        final sharedText = value.first.path;
        _handleSharedContent(sharedText);
      }
    }, onError: (err) {
      debugPrint("Share intent stream error: $err");
    });

    // 앱이 종료된 상태에서 공유로 시작된 경우
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        final sharedText = value.first.path;
        _handleSharedContent(sharedText);
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  void _handleSharedContent(String content) {
    // URL 추출 (텍스트에서 URL만 추출)
    final urlPattern = RegExp(
      r'https?://[^\s<>"{}|\\^`\[\]]+',
      caseSensitive: false,
    );

    final match = urlPattern.firstMatch(content);
    if (match != null) {
      final url = match.group(0)!;
      debugPrint('Shared URL received: $url');
      _pendingSharedUrl = url;
      _sharedUrlController.add(url);
    } else if (content.startsWith('http')) {
      debugPrint('Shared URL received: $content');
      _pendingSharedUrl = content;
      _sharedUrlController.add(content);
    }
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
    _sharedUrlController.close();
  }
}
