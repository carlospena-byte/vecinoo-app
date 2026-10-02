import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../paging/paged_notifier.dart';
import '../theme/app_theme.dart';

/// Scrolling list over a [PagedState]: asks for the next page when the
/// resident nears the end, shows a spinner while it loads and a retry after
/// a failure (only the retry asks again then), and supports pull to refresh.
class GatesPagedList<T> extends StatelessWidget {
  const GatesPagedList({
    super.key,
    required this.items,
    required this.state,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.onRefresh,
    required this.padding,
  });

  /// What to render; may be a slice of [PagedState.items].
  final List<T> items;
  final PagedState<T> state;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final EdgeInsets padding;

  static const _prefetchExtent = 300.0;

  @override
  Widget build(BuildContext context) {
    final showFooter = state.loading || state.failure != null;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (state.failure == null &&
              n.metrics.extentAfter < _prefetchExtent) {
            onLoadMore();
          }
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          itemCount: items.length + (showFooter ? 1 : 0),
          separatorBuilder: (_, _) =>
              const SizedBox(height: GatesSpacing.space12),
          itemBuilder: (context, index) {
            if (index == items.length) {
              return _Footer(
                failed: state.failure != null,
                onRetry: onLoadMore,
              );
            }
            return itemBuilder(context, items[index]);
          },
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!failed) {
      return const Padding(
        padding: EdgeInsets.all(GatesSpacing.space16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      children: [
        Text(
          context.l10n.commonLoadMoreError,
          textAlign: TextAlign.center,
          style: context.gatesText.labelSecondary,
        ),
        TextButton(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
      ],
    );
  }
}
