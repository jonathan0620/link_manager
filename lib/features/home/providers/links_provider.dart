import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/link_model.dart';
import '../data/repositories/link_repository.dart';

/// Link repository provider
final linkRepositoryProvider = Provider<LinkRepository>((ref) {
  return LinkRepository();
});

/// All links stream provider
final linksStreamProvider = StreamProvider<List<LinkModel>>((ref) {
  final repository = ref.watch(linkRepositoryProvider);
  return repository.getLinksStream();
});

/// Recent links stream provider
final recentLinksStreamProvider = StreamProvider<List<LinkModel>>((ref) {
  final repository = ref.watch(linkRepositoryProvider);
  return repository.getRecentLinksStream(limit: 10);
});

/// Unread links stream provider
final unreadLinksStreamProvider = StreamProvider<List<LinkModel>>((ref) {
  final repository = ref.watch(linkRepositoryProvider);
  return repository.getUnreadLinksStream();
});

/// Links by label stream provider
final linksByLabelStreamProvider =
    StreamProvider.family<List<LinkModel>, String>((ref, label) {
  final repository = ref.watch(linkRepositoryProvider);
  return repository.getLinksByLabelStream(label);
});

/// Favorite links stream provider
final favoriteLinksStreamProvider = StreamProvider<List<LinkModel>>((ref) {
  final repository = ref.watch(linkRepositoryProvider);
  return repository.getFavoriteLinksStream();
});

/// Single link provider
final linkProvider = FutureProvider.family<LinkModel?, String>((ref, linkId) {
  final repository = ref.watch(linkRepositoryProvider);
  return repository.getLinkById(linkId);
});

/// Unique labels provider
final uniqueLabelsProvider = FutureProvider<List<String>>((ref) {
  final repository = ref.watch(linkRepositoryProvider);
  return repository.getUniqueLabels();
});

/// Label counts provider - returns Map<label, count>
final labelCountsProvider = StreamProvider<Map<String, int>>((ref) {
  final repository = ref.watch(linkRepositoryProvider);
  return repository.getLinksStream().map((links) {
    final counts = <String, int>{};
    for (final link in links) {
      if (link.label != null && link.label!.isNotEmpty) {
        counts[link.label!] = (counts[link.label!] ?? 0) + 1;
      }
    }
    return counts;
  });
});

/// Link counts provider
final linkCountsProvider = FutureProvider<LinkCounts>((ref) async {
  final repository = ref.watch(linkRepositoryProvider);
  final total = await repository.getTotalLinkCount();
  final unread = await repository.getUnreadLinkCount();
  return LinkCounts(total: total, unread: unread);
});

class LinkCounts {
  final int total;
  final int unread;

  const LinkCounts({required this.total, required this.unread});
}

/// Link actions notifier
class LinkActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final LinkRepository _repository;

  LinkActionsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<LinkModel?> addLink({
    required String url,
    required String title,
    String? thumbnailUrl,
    String? label,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. 먼저 링크 저장 (빠른 UX를 위해)
      final link = await _repository.addLink(
        url: url,
        title: title,
        thumbnailUrl: thumbnailUrl,
        label: label,
      );
      state = const AsyncValue.data(null);

      // 2. 백그라운드에서 AI 요약 생성 (임시 비활성화 - API 할당량 문제)
      // _generateSummaryInBackground(link.id, url);

      return link;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// 백그라운드에서 AI 요약 생성 (Cloud Function 호출)
  Future<void> _generateSummaryInBackground(String linkId, String url) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generateAISummary');

      final result = await callable.call({
        'linkId': linkId,
        'url': url,
      });

      final data = result.data as Map<String, dynamic>;
      if (data['success'] == true) {
        debugPrint('AI 요약 생성 완료: ${data['summary']}');
      }
    } catch (e) {
      // 요약 실패해도 링크는 이미 저장됨
      debugPrint('AI 요약 생성 실패: $e');
    }
  }

  Future<bool> updateLink({
    required String linkId,
    String? url,
    String? title,
    String? thumbnailUrl,
    String? label,
    bool? isRead,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateLink(
        linkId: linkId,
        url: url,
        title: title,
        thumbnailUrl: thumbnailUrl,
        label: label,
        isRead: isRead,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteLink(String linkId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteLink(linkId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> markAsRead(String linkId) async {
    try {
      await _repository.markAsRead(linkId);
    } catch (e) {
      // Silent fail for mark as read
    }
  }

  Future<void> toggleFavorite(String linkId) async {
    try {
      await _repository.toggleFavorite(linkId);
    } catch (e) {
      // Silent fail for toggle favorite
    }
  }
}

/// Link actions provider
final linkActionsProvider =
    StateNotifierProvider<LinkActionsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(linkRepositoryProvider);
  return LinkActionsNotifier(repository);
});
