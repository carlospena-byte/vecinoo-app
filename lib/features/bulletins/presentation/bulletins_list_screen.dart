import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_paged_list.dart';
import '../../../core/widgets/gates_segmented_tabs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/l10n.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/bulletin.dart';
import 'bulletins_controller.dart';

final _dateFormat = DateFormat("d 'de' MMMM y", 'es');

enum _BulletinsTab { newest, history }

/// Published bulletins, newest first, split into "Nuevos" (not opened yet)
/// and "Historial" (already read). Pages of [bulletinsPageSize] load as the
/// resident scrolls. Reached from the Home "Boletines" card; tapping one
/// opens its detail.
class BulletinsListScreen extends ConsumerStatefulWidget {
  const BulletinsListScreen({super.key, this.startOnHistory = false});

  /// Opens on "Historial" (the Home card has nothing new to show).
  final bool startOnHistory;

  @override
  ConsumerState<BulletinsListScreen> createState() =>
      _BulletinsListScreenState();
}

class _BulletinsListScreenState extends ConsumerState<BulletinsListScreen> {
  late _BulletinsTab _tab = widget.startOnHistory
      ? _BulletinsTab.history
      : _BulletinsTab.newest;

  @override
  Widget build(BuildContext context) {
    final residentialId = ref
        .watch(selectedMembershipProvider)
        .value
        ?.residentialId;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(context.l10n.bulletinsTitle),
      ),
      body: residentialId == null
          ? const LoadingView()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    GatesSpacing.space24,
                    GatesSpacing.space8,
                    GatesSpacing.space24,
                    0,
                  ),
                  child: GatesSegmentedTabs<_BulletinsTab>(
                    options: [
                      GatesSegmentedTabOption(
                        value: _BulletinsTab.newest,
                        label: context.l10n.bulletinsTabNew,
                      ),
                      GatesSegmentedTabOption(
                        value: _BulletinsTab.history,
                        label: context.l10n.bulletinsTabHistory,
                      ),
                    ],
                    selected: _tab,
                    onSelect: (tab) => setState(() => _tab = tab),
                  ),
                ),
                Expanded(
                  child: _BulletinsBody(
                    residentialId: residentialId,
                    tab: _tab,
                  ),
                ),
              ],
            ),
    );
  }
}

class _BulletinsBody extends ConsumerWidget {
  const _BulletinsBody({required this.residentialId, required this.tab});

  final String residentialId;
  final _BulletinsTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paging = ref.watch(bulletinsPagingProvider(residentialId));
    final readIds = ref.watch(bulletinReadIdsProvider(residentialId));

    if (paging.items.isEmpty) {
      if (paging.failure != null) {
        return ErrorView(
          message: context.l10n.bulletinsListLoadError,
          onRetry: () => ref
              .read(bulletinsPagingProvider(residentialId).notifier)
              .refresh(),
        );
      }
      if (paging.loading) return const LoadingView();
      return EmptyView(
        message: context.l10n.bulletinsEmpty,
        icon: TablerIcons.news,
      );
    }

    final showRead = tab == _BulletinsTab.history;
    return _BulletinsPage(
      residentialId: residentialId,
      bulletins: [
        for (final b in paging.items)
          if (readIds.contains(b.id) == showRead) b,
      ],
      emptyMessage: showRead
          ? context.l10n.bulletinsEmptyHistory
          : context.l10n.bulletinsEmptyNew,
    );
  }
}

/// One tab: its slice of the loaded bulletins. Keeps requesting pages while
/// the slice is too short to scroll (the other tab may hold most of a page).
class _BulletinsPage extends ConsumerWidget {
  const _BulletinsPage({
    required this.residentialId,
    required this.bulletins,
    required this.emptyMessage,
  });

  final String residentialId;
  final List<Bulletin> bulletins;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paging = ref.watch(bulletinsPagingProvider(residentialId));
    final controller = ref.read(
      bulletinsPagingProvider(residentialId).notifier,
    );

    if (paging.hasMore &&
        !paging.loading &&
        paging.failure == null &&
        bulletins.length < bulletinsPageSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) controller.loadMore();
      });
    }

    if (bulletins.isEmpty && !paging.loading && paging.failure == null) {
      return EmptyView(message: emptyMessage, icon: TablerIcons.news);
    }
    return GatesPagedList<Bulletin>(
      items: bulletins,
      state: paging,
      onLoadMore: controller.loadMore,
      onRefresh: controller.refresh,
      padding: EdgeInsets.fromLTRB(
        GatesSpacing.space24,
        GatesSpacing.space16,
        GatesSpacing.space24,
        GatesSpacing.space24 + MediaQuery.paddingOf(context).bottom,
      ),
      itemBuilder: (context, bulletin) => BulletinCard(
        bulletin: bulletin,
        onTap: () => context.push('/bulletins/${bulletin.id}'),
      ),
    );
  }
}

class BulletinCard extends StatelessWidget {
  const BulletinCard({super.key, required this.bulletin, required this.onTap});

  final Bulletin bulletin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final excerpt = bulletin.excerpt;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(GatesSpacing.space16),
          decoration: BoxDecoration(
            color: context.palette.bgSurface,
            border: Border.all(color: context.palette.borderDefault),
            borderRadius: BorderRadius.circular(GatesRadius.radius16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _dateFormat.format(bulletin.publishedAt),
                style: context.gatesText.caption,
              ),
              const SizedBox(height: GatesSpacing.space4),
              Text(
                bulletin.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GatesTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (excerpt.isNotEmpty) ...[
                const SizedBox(height: GatesSpacing.space4),
                Text(
                  excerpt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.gatesText.labelSecondary,
                ),
              ],
              if (bulletin.imageCount > 0 || bulletin.pdfCount > 0) ...[
                const SizedBox(height: GatesSpacing.space12),
                Wrap(
                  spacing: GatesSpacing.space16,
                  runSpacing: GatesSpacing.space4,
                  children: [
                    if (bulletin.imageCount > 0)
                      _AttachmentCount(
                        icon: TablerIcons.photo,
                        label: context.l10n.bulletinsImageCount(
                          bulletin.imageCount,
                        ),
                      ),
                    if (bulletin.pdfCount > 0)
                      _AttachmentCount(
                        icon: TablerIcons.fileTypePdf,
                        label: context.l10n.bulletinsPdfCount(
                          bulletin.pdfCount,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentCount extends StatelessWidget {
  const _AttachmentCount({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: context.palette.textBrand),
        const SizedBox(width: GatesSpacing.space4),
        Flexible(child: Text(label, style: context.gatesText.caption)),
      ],
    );
  }
}
