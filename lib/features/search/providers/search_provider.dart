import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/data/models/link_model.dart';
import '../../home/data/repositories/link_repository.dart';
import '../../home/providers/links_provider.dart';

/// Search state
class SearchState {
  final String query;
  final List<LinkModel> results;
  final bool isLoading;
  final bool hasSearched;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.hasSearched = false,
  });

  SearchState copyWith({
    String? query,
    List<LinkModel>? results,
    bool? isLoading,
    bool? hasSearched,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }
}

/// Search notifier
class SearchNotifier extends StateNotifier<SearchState> {
  final LinkRepository _repository;

  SearchNotifier(this._repository) : super(const SearchState());

  void updateQuery(String query) {
    state = state.copyWith(query: query);
  }

  Future<void> search() async {
    if (state.query.isEmpty) {
      state = state.copyWith(
        results: [],
        hasSearched: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final results = await _repository.searchLinks(state.query);
      state = state.copyWith(
        results: results,
        isLoading: false,
        hasSearched: true,
      );
    } catch (e) {
      state = state.copyWith(
        results: [],
        isLoading: false,
        hasSearched: true,
      );
    }
  }

  void clearSearch() {
    state = const SearchState();
  }
}

/// Search provider
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final repository = ref.watch(linkRepositoryProvider);
  return SearchNotifier(repository);
});
