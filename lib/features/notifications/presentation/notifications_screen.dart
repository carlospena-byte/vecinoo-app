import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/notifications/push_navigation.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_paged_list.dart';
import '../../../core/widgets/gates_segmented_tabs.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/l10n.dart';
import '../domain/user_notification.dart';
import 'notifications_controller.dart';

enum _NotificationsTab { newest, history }

/// The bell's inbox: pushes and in-app events, newest first, split into
/// "Nuevas" (unread) and "Historial" (already read). Pages of
/// [notificationsPageSize] load as the resident scrolls. Tapping one marks it
/// read (it moves to "Historial") and opens its destination, like a tapped
/// push.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  _NotificationsTab _tab = _NotificationsTab.newest;

  @override
  Widget build(BuildContext context) {
    final paging = ref.watch(notificationsPagingProvider);
    final controller = ref.read(notificationsPagingProvider.notifier);

    // A notification arriving while the inbox is open: reload the first page.
    ref.listen(unreadNotificationsCountProvider, (previous, next) {
      final before = previous?.value;
      final after = next.value;
      if (before != null && after != null && after > before) {
        controller.refresh();
      }
    });

    final hasUnread = paging.items.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(context.l10n.notificationsTitle),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () async {
                final ok = await controller.markAllRead();
                if (!ok && context.mounted) {
                  showGatesToast(
                    context,
                    type: GatesToastType.error,
                    title: context.l10n.notificationsMarkAllReadFailed,
                  );
                }
              },
              child: Text(context.l10n.notificationsMarkAllRead),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GatesSpacing.space24,
              GatesSpacing.space8,
              GatesSpacing.space24,
              0,
            ),
            child: GatesSegmentedTabs<_NotificationsTab>(
              options: [
                GatesSegmentedTabOption(
                  value: _NotificationsTab.newest,
                  label: context.l10n.notificationsTabNew,
                ),
                GatesSegmentedTabOption(
                  value: _NotificationsTab.history,
                  label: context.l10n.notificationsTabHistory,
                ),
              ],
              selected: _tab,
              onSelect: (tab) => setState(() => _tab = tab),
            ),
          ),
          Expanded(child: _NotificationsBody(tab: _tab)),
        ],
      ),
    );
  }
}

class _NotificationsBody extends ConsumerWidget {
  const _NotificationsBody({required this.tab});

  final _NotificationsTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paging = ref.watch(notificationsPagingProvider);
    final controller = ref.read(notificationsPagingProvider.notifier);

    if (paging.items.isEmpty) {
      if (paging.failure != null) {
        return ErrorView(
          message: context.l10n.notificationsLoadError,
          onRetry: controller.refresh,
        );
      }
      if (paging.loading) return const LoadingView();
      return EmptyView(
        message: context.l10n.notificationsEmpty,
        icon: TablerIcons.bell,
      );
    }

    final showRead = tab == _NotificationsTab.history;
    final notifications = [
      for (final n in paging.items)
        if (n.isRead == showRead) n,
    ];

    // Keep requesting pages while the slice is too short to scroll (the other
    // tab may hold most of a page).
    if (paging.hasMore &&
        !paging.loading &&
        paging.failure == null &&
        notifications.length < notificationsPageSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) controller.loadMore();
      });
    }

    if (notifications.isEmpty && !paging.loading && paging.failure == null) {
      return EmptyView(
        message: showRead
            ? context.l10n.notificationsEmptyHistory
            : context.l10n.notificationsEmptyNew,
        icon: TablerIcons.bell,
      );
    }

    return GatesPagedList<UserNotification>(
      items: notifications,
      state: paging,
      onLoadMore: controller.loadMore,
      onRefresh: controller.refresh,
      padding: EdgeInsets.fromLTRB(
        GatesSpacing.space24,
        GatesSpacing.space16,
        GatesSpacing.space24,
        GatesSpacing.space24 + MediaQuery.paddingOf(context).bottom,
      ),
      itemBuilder: (context, notification) => NotificationCard(
        notification: notification,
        onTap: () {
          controller.markRead(notification.id);
          final route = notificationRoute(notification.data);
          if (route != null) context.push(route);
        },
      ),
    );
  }
}

IconData _iconFor(String type) => switch (type) {
  'bulletin' => TablerIcons.news,
  'payment' => TablerIcons.cash,
  'charge' => TablerIcons.receipt,
  'visitor_checkin' => TablerIcons.userCheck,
  'booking' => TablerIcons.calendarEvent,
  'incident' => TablerIcons.alertTriangle,
  _ => TablerIcons.speakerphone,
};

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final UserNotification notification;
  final VoidCallback onTap;

  static final _dateFormat = DateFormat("d 'de' MMMM y, h:mm a", 'es');

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: notification.title,
      value: notification.body,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: palette.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GatesRadius.radius16),
          side: BorderSide(color: palette.borderDefault),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(GatesSpacing.space16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.bgAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconFor(notification.type),
                    size: 20,
                    color: palette.iconBrand,
                  ),
                ),
                const SizedBox(width: GatesSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dateFormat.format(notification.createdAt),
                        style: context.gatesText.caption,
                      ),
                      const SizedBox(height: GatesSpacing.space4),
                      Text(
                        notification.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GatesTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: GatesSpacing.space4),
                      Text(
                        notification.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: context.gatesText.labelSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
