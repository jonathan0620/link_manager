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
      final link = await _repository.addLink(
        url: url,
        title: title,
        thumbnailUrl: thumbnailUrl,
        label: label,
      );
      state = const AsyncValue.data(null);
      return link;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
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
}

/// Link actions provider
final linkActionsProvider =
    StateNotifierProvider<LinkActionsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(linkRepositoryProvider);
  return LinkActionsNotifier(repository);
});
