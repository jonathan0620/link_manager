/// URL Sanitizer for security
/// Prevents XSS attacks and validates URL format
class UrlSanitizer {
  // Allowed protocols
  static const _allowedProtocols = ['http', 'https'];

  // Dangerous protocols to block
  static const _blockedProtocols = [
    'javascript',
    'data',
    'vbscript',
    'file',
    'about',
    'blob',
  ];

  /// Validate and sanitize URL
  /// Returns sanitized URL or null if invalid/dangerous
  static String? sanitize(String url) {
    if (url.isEmpty) return null;

    // Trim whitespace
    var sanitized = url.trim();

    // Remove any null bytes or control characters
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    // Decode URL-encoded characters to check for obfuscation
    try {
      final decoded = Uri.decodeFull(sanitized.toLowerCase());

      // Check for blocked protocols
      for (final protocol in _blockedProtocols) {
        if (decoded.startsWith('$protocol:')) {
          return null; // Dangerous URL
        }
      }
    } catch (e) {
      // If decoding fails, the URL might be malformed
    }

    // Add https:// if no protocol specified
    if (!sanitized.contains('://')) {
      sanitized = 'https://$sanitized';
    }

    // Parse and validate URL
    try {
      final uri = Uri.parse(sanitized);

      // Check if protocol is allowed
      if (!_allowedProtocols.contains(uri.scheme.toLowerCase())) {
        return null;
      }

      // Check if host exists
      if (uri.host.isEmpty) {
        return null;
      }

      // Rebuild URL to normalize it
      return uri.toString();
    } catch (e) {
      return null;
    }
  }

  /// Check if URL is valid (without modifying it)
  static bool isValid(String url) {
    return sanitize(url) != null;
  }

  /// Get validation result with message
  static UrlValidationResult validate(String url) {
    if (url.isEmpty) {
      return UrlValidationResult(
        isValid: false,
        message: 'URL을 입력해 주세요.',
      );
    }

    final sanitized = sanitize(url);

    if (sanitized == null) {
      // Check specific reasons
      final lower = url.toLowerCase().trim();

      for (final protocol in _blockedProtocols) {
        if (lower.startsWith('$protocol:')) {
          return UrlValidationResult(
            isValid: false,
            message: '허용되지 않는 URL 형식입니다.',
          );
        }
      }

      return UrlValidationResult(
        isValid: false,
        message: '유효한 URL을 입력해 주세요.',
      );
    }

    return UrlValidationResult(
      isValid: true,
      sanitizedUrl: sanitized,
      message: '유효한 URL입니다.',
    );
  }

  /// Extract domain from URL for display
  static String? extractDomain(String url) {
    try {
      final sanitized = sanitize(url);
      if (sanitized == null) return null;

      final uri = Uri.parse(sanitized);
      return uri.host;
    } catch (e) {
      return null;
    }
  }
}

class UrlValidationResult {
  final bool isValid;
  final String? sanitizedUrl;
  final String message;

  const UrlValidationResult({
    required this.isValid,
    this.sanitizedUrl,
    required this.message,
  });
}
