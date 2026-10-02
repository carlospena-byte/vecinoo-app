import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/failure.dart';

/// Items loaded so far by a [PagedNotifier], plus paging status.
class PagedState<T> {
  const PagedState({
    this.items = const [],
    this.loading = true,
    this.hasMore = true,
    this.failure,
  });

  final List<T> items;

  /// A page request is in flight (the first one included).
  final bool loading;
  final bool hasMore;

  /// The last request failed; cleared by the next one.
  final Failure? failure;

  PagedState<T> copyWith({
    List<T>? items,
    bool? loading,
    bool? hasMore,
    Failure? failure,
    bool clearFailure = false,
  }) => PagedState<T>(
    items: items ?? this.items,
    loading: loading ?? this.loading,
    hasMore: hasMore ?? this.hasMore,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

/// Pages through a list [pageSize] items at a time (lazy loading). The first
/// page starts loading as soon as the provider is first read; a page shorter
/// than [pageSize] is the last one.
abstract class PagedNotifier<T> extends Notifier<PagedState<T>> {
  static const defaultPageSize = 10;

  int get pageSize => defaultPageSize;

  /// Fetches up to [limit] items starting at [offset]; throws `Failure`s.
  Future<List<T>> fetchPage({required int offset, required int limit});

  bool _inFlight = false;

  @override
  PagedState<T> build() {
    Future.microtask(loadMore);
    return PagedState<T>();
  }

  /// Fetches the next page; a no-op while one is loading or none is left.
  Future<void> loadMore() async {
    final current = state;
    if (_inFlight || !current.hasMore) return;
    _inFlight = true;
    state = current.copyWith(loading: true, clearFailure: true);
    try {
      final page = await fetchPage(
        offset: current.items.length,
        limit: pageSize,
      );
      state = state.copyWith(
        items: [...state.items, ...page],
        loading: false,
        hasMore: page.length == pageSize,
      );
    } on Failure catch (failure) {
      state = state.copyWith(loading: false, failure: failure);
    } finally {
      _inFlight = false;
    }
  }

  /// Starts over from the first page (pull to refresh, retry).
  Future<void> refresh() async {
    if (_inFlight) return;
    state = PagedState<T>();
    await loadMore();
  }
}
