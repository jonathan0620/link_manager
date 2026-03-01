import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
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
    state = state.copyWith(url: url);

    if (url.isEmpty) {
      state = state.copyWith(
        title: '',
        thumbnailUrl: null,
      );
      return;
    }

    // Validate URL format
    final urlWithProtocol = url.startsWith('http') ? url : 'https://$url';

    try {
      final uri = Uri.parse(urlWithProtocol);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return;
      }
    } catch (e) {
      return;
    }

    // Fetch metadata
    await _fetchMetadata(urlWithProtocol);
  }

  Future<void> _fetchMetadata(String url) async {
    state = state.copyWith(isFetchingMetadata: true);

    try {
      final metadata = await MetadataFetch.extract(url);

      if (metadata != null) {
        state = state.copyWith(
          title: metadata.title ?? state.title,
          thumbnailUrl: metadata.image ?? state.thumbnailUrl,
          isFetchingMetadata: false,
        );
      } else {
        state = state.copyWith(isFetchingMetadata: false);
      }
    } catch (e) {
      state = state.copyWith(
        isFetchingMetadata: false,
        title: state.title.isEmpty ? '제목 없음' : state.title,
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
