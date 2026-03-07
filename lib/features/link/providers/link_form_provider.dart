import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../../../core/utils/url_sanitizer.dart';
import '../../home/data/models/link_model.dart';

/// Link form state
class LinkFormState {
  final String url;
  final String title;
  final String? thumbnailUrl;
  final String? label;
  final bool isLoading;
  final bool isFetchingMetadata;
  final String? error;

  const LinkFormState({
    this.url = '',
    this.title = '',
    this.thumbnailUrl,
    this.label,
    this.isLoading = false,
    this.isFetchingMetadata = false,
    this.error,
  });

  LinkFormState copyWith({
    String? url,
    String? title,
    String? thumbnailUrl,
    String? label,
    bool? isLoading,
    bool? isFetchingMetadata,
    String? error,
  }) {
    return LinkFormState(
      url: url ?? this.url,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      label: label ?? this.label,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMetadata: isFetchingMetadata ?? this.isFetchingMetadata,
      error: error,
    );
  }

  bool get isValid => url.isNotEmpty;
}

/// Link form notifier
class LinkFormNotifier extends StateNotifier<LinkFormState> {
  LinkFormNotifier() : super(const LinkFormState());

  /// Initialize with existing link data (for editing)
  void initWithLink(LinkModel link) {
    state = LinkFormState(
      url: link.url,
      title: link.title,
      thumbnailUrl: link.thumbnailUrl,
      label: link.label,
    );
  }

  /// Reset form
  void reset() {
    state = const LinkFormState();
  }

  /// Update URL and fetch metadata
  Future<void> updateUrl(String url) async {
    state = state.copyWith(url: url, error: null);

    if (url.isEmpty) {
      state = state.copyWith(
        title: '',
        thumbnailUrl: null,
      );
      return;
    }

    // Validate and sanitize URL for security
    final validationResult = UrlSanitizer.validate(url);

    if (!validationResult.isValid) {
      state = state.copyWith(error: validationResult.message);
      return;
    }

    final sanitizedUrl = validationResult.sanitizedUrl!;
    state = state.copyWith(url: sanitizedUrl, error: null);

    // Fetch metadata
    await _fetchMetadata(sanitizedUrl);
  }

  Future<void> _fetchMetadata(String url) async {
    state = state.copyWith(isFetchingMetadata: true);

    try {
      // Try Cloud Function first (works on web)
      if (kIsWeb) {
        await _fetchMetadataViaCloudFunction(url);
      } else {
        // On mobile, we can fetch directly
        await _fetchMetadataDirectly(url);
      }
    } catch (e) {
      debugPrint('[LinkFormNotifier] Error fetching metadata: $e');
      state = state.copyWith(
        isFetchingMetadata: false,
        title: state.title.isEmpty ? '' : state.title,
      );
    }
  }

  Future<void> _fetchMetadataViaCloudFunction(String url) async {
    // Try multiple free APIs as fallback

    // 1. Try Microlink API first (50 req/day free)
    try {
      final apiUrl = 'https://api.microlink.io/?url=${Uri.encodeComponent(url)}';
      final response = await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode == 200) {
        final data = _parseJson(response.body);

        if (data != null && data['status'] == 'success') {
          final dataObj = data['data'] as Map<String, dynamic>?;
          if (dataObj != null) {
            final title = dataObj['title'] as String? ?? '';
            final imageData = dataObj['image'] as Map<String, dynamic>?;
            final imageUrl = imageData?['url'] as String? ?? '';

            if (title.isNotEmpty || imageUrl.isNotEmpty) {
              state = state.copyWith(
                title: title.isNotEmpty ? title : state.title,
                thumbnailUrl: imageUrl.isNotEmpty ? imageUrl : state.thumbnailUrl,
                isFetchingMetadata: false,
              );
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[LinkFormNotifier] Microlink API error: $e');
    }

    // 2. Try jsonlink.io as fallback (free, unlimited)
    try {
      final apiUrl = 'https://jsonlink.io/api/extract?url=${Uri.encodeComponent(url)}';
      final response = await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode == 200) {
        final data = _parseJson(response.body);

        if (data != null) {
          final title = data['title'] as String? ?? '';
          final images = data['images'] as List<dynamic>?;
          final imageUrl = (images != null && images.isNotEmpty)
              ? images[0] as String? ?? ''
              : '';

          if (title.isNotEmpty || imageUrl.isNotEmpty) {
            state = state.copyWith(
              title: title.isNotEmpty ? title : state.title,
              thumbnailUrl: imageUrl.isNotEmpty ? imageUrl : state.thumbnailUrl,
              isFetchingMetadata: false,
            );
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[LinkFormNotifier] jsonlink.io API error: $e');
    }

    // 3. If all else fails, use website screenshot as thumbnail
    try {
      final uri = Uri.parse(url);
      final screenshotUrl = 'https://image.thum.io/get/width/300/${uri.toString()}';

      state = state.copyWith(
        title: state.title.isNotEmpty ? state.title : uri.host,
        thumbnailUrl: screenshotUrl,
        isFetchingMetadata: false,
      );
      return;
    } catch (e) {
      debugPrint('[LinkFormNotifier] Screenshot fallback error: $e');
    }

    state = state.copyWith(isFetchingMetadata: false);
  }

  Map<String, dynamic>? _parseJson(String body) {
    try {
      return Map<String, dynamic>.from(
        (const JsonDecoder().convert(body)) as Map,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _fetchMetadataDirectly(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);

        // Extract title
        String? title;
        final ogTitle = document.querySelector('meta[property="og:title"]');
        if (ogTitle != null) {
          title = ogTitle.attributes['content'];
        }
        title ??= document.querySelector('title')?.text;

        // Extract image
        String? imageUrl;
        final ogImage = document.querySelector('meta[property="og:image"]');
        if (ogImage != null) {
          imageUrl = ogImage.attributes['content'];
          // Handle relative URLs
          if (imageUrl != null && !imageUrl.startsWith('http')) {
            final uri = Uri.parse(url);
            imageUrl = '${uri.scheme}://${uri.host}$imageUrl';
          }
        }

        state = state.copyWith(
          title: title ?? state.title,
          thumbnailUrl: imageUrl ?? state.thumbnailUrl,
          isFetchingMetadata: false,
        );
      } else {
        state = state.copyWith(isFetchingMetadata: false);
      }
    } catch (e) {
      state = state.copyWith(
        isFetchingMetadata: false,
        title: state.title.isEmpty ? '' : state.title,
      );
    }
  }

  /// Update title
  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  /// Update label
  void updateLabel(String? label) {
    state = state.copyWith(label: label);
  }

  /// Set loading state
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Set error
  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

/// Link form provider
final linkFormProvider =
    StateNotifierProvider.autoDispose<LinkFormNotifier, LinkFormState>((ref) {
  return LinkFormNotifier();
});
