import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Share helper for sharing links
class ShareHelper {
  /// Copy URL to clipboard
  static Future<bool> copyToClipboard(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      return true;
    } catch (e) {
      debugPrint('[ShareHelper] Copy failed: $e');
      return false;
    }
  }

  /// Share via native share dialog (mobile) or clipboard (web)
  static Future<void> shareLink({
    required String url,
    required String title,
  }) async {
    final shareText = '$title\n$url';

    if (kIsWeb) {
      // On web, use Web Share API if available, otherwise copy to clipboard
      await copyToClipboard(url);
    } else {
      // On mobile, use native share
      await Share.share(shareText, subject: title);
    }
  }

  /// Share via KakaoTalk
  /// Uses Kakao Link URL scheme
  static Future<bool> shareViaKakaoTalk({
    required String url,
    required String title,
  }) async {
    // KakaoTalk share URL scheme
    // This uses the Kakao Link API via URL scheme
    // Format: https://sharer.kakao.com/talk/friends/picker/link

    final kakaoShareUrl = Uri.parse(
      'https://story.kakao.com/share?url=${Uri.encodeComponent(url)}',
    );

    // Alternative: Use KakaoTalk app scheme (mobile only)
    final kakaoAppUrl = Uri.parse(
      'kakaolink://send?text=${Uri.encodeComponent('$title\n$url')}',
    );

    try {
      if (!kIsWeb) {
        // Try to open KakaoTalk app first (mobile)
        if (await canLaunchUrl(kakaoAppUrl)) {
          await launchUrl(kakaoAppUrl, mode: LaunchMode.externalApplication);
          return true;
        }
      }

      // Fallback to Kakao Story web share
      if (await canLaunchUrl(kakaoShareUrl)) {
        await launchUrl(kakaoShareUrl, mode: LaunchMode.externalApplication);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('[ShareHelper] Kakao share failed: $e');
      return false;
    }
  }

  /// Share via general share with URL
  static Future<void> shareViaUrl({
    required String url,
    required String title,
    required SharePlatform platform,
  }) async {
    final encodedUrl = Uri.encodeComponent(url);
    final encodedTitle = Uri.encodeComponent(title);

    String shareUrl;
    switch (platform) {
      case SharePlatform.twitter:
        shareUrl = 'https://twitter.com/intent/tweet?url=$encodedUrl&text=$encodedTitle';
        break;
      case SharePlatform.facebook:
        shareUrl = 'https://www.facebook.com/sharer/sharer.php?u=$encodedUrl';
        break;
      case SharePlatform.linkedin:
        shareUrl = 'https://www.linkedin.com/sharing/share-offsite/?url=$encodedUrl';
        break;
      case SharePlatform.email:
        shareUrl = 'mailto:?subject=$encodedTitle&body=$encodedUrl';
        break;
    }

    final uri = Uri.parse(shareUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

enum SharePlatform {
  twitter,
  facebook,
  linkedin,
  email,
}
