import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category_model.dart';
import '../data/repositories/link_repository.dart';
import 'links_provider.dart';

/// Categories stream provider
final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  final repository = ref.watch(linkRepositoryProvider);
  return repository.getCategoriesStream();
});

/// Category actions notifier
class CategoryActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final LinkRepository _repository;

  CategoryActionsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<CategoryModel?> addCategory(String name) async {
    state = const AsyncValue.loading();
    try {
      final category = await _repository.addCategory(name);
      state = const AsyncValue.data(null);
      return category;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteCategory(categoryId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Category actions provider
final categoryActionsProvider =
    StateNotifierProvider<CategoryActionsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(linkRepositoryProvider);
  return CategoryActionsNotifier(repository);
});

/// Selected category provider (for filtering)
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Category with link count provider
final categoryLinkCountProvider =
    FutureProvider.family<int, String>((ref, label) async {
  final repository = ref.watch(linkRepositoryProvider);
  return repository.getLinkCountByLabel(label);
});
