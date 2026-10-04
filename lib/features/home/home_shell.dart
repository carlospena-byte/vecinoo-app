import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../core/notifications/push_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../amenities/presentation/bookings_list_screen.dart';
import '../incidents/presentation/incidents_list_screen.dart';
import '../visits/presentation/visits_list_screen.dart';
import 'presentation/home_screen.dart';
import '../../l10n/l10n.dart';

/// Asks the [HomeShell] to select a tab, e.g. `context.go('/', extra:
/// HomeTabRequest(HomeShell.bookingsTab))`. Compared by identity, so
/// requesting the same tab twice still switches to it after the user
/// navigated elsewhere in between.
class HomeTabRequest {
  const HomeTabRequest(this.index);

  final int index;
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.tabRequest});

  static const bookingsTab = 2;
  static const visitsTab = 3;

  /// Identifies the bottom navigation bar (used by tests).
  static const navBarKey = Key('home-bottom-nav');

  final HomeTabRequest? tabRequest;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.tabRequest?.index ?? 0;

  @override
  void initState() {
    super.initState();
    PushNavigation.pendingRoute.addListener(_openPendingRoute);
    // A cold start from a notification tap queued its route before this
    // shell existed.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingRoute());
  }

  @override
  void dispose() {
    PushNavigation.pendingRoute.removeListener(_openPendingRoute);
    super.dispose();
  }

  /// Opens the screen a tapped push notification points at (e.g. a bulletin).
  void _openPendingRoute() {
    final route = PushNavigation.pendingRoute.value;
    if (route == null || !mounted) return;
    PushNavigation.pendingRoute.value = null;
    context.push(route);
  }

  @override
  void didUpdateWidget(HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final request = widget.tabRequest;
    if (request != null && !identical(request, oldWidget.tabRequest)) {
      _index = request.index;
    }
  }

  void _goToTab(int index) => setState(() => _index = index);

  /// The tab screens stay alive in the [IndexedStack], so each one is told
  /// when it becomes the selected tab and refetches its list.
  List<Widget> get _screens => [
    HomeScreen(onNavigateToTab: _goToTab),
    IncidentsListScreen(active: _index == 1),
    BookingsListScreen(active: _index == 2),
    VisitsListScreen(active: _index == 3),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final destinations = [
      _NavItem(icon: TablerIcons.home, label: l10n.homeNavHome),
      _NavItem(icon: TablerIcons.alertTriangle, label: l10n.homeIncidents),
      _NavItem(icon: TablerIcons.calendar, label: l10n.homeReservations),
      _NavItem(icon: TablerIcons.users, label: l10n.homeVisits),
    ];
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      // Bottom nav labels are short and the capsule has fixed height, so it
      // ignores the system's text-scale setting (like Material's own
      // NavigationBar) instead of overflowing under larger accessibility
      // font sizes.
      bottomNavigationBar: MediaQuery.withNoTextScaling(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Container(
            key: HomeShell.navBarKey,
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: context.palette.bgSurface,
              borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: context.palette.shadow,
                  offset: const Offset(0, 4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: _NavPillItem(
                      item: destinations[i],
                      selected: i == _index,
                      onTap: () => _goToTab(i),
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

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _NavPillItem extends StatelessWidget {
  const _NavPillItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = selected ? palette.textBrand : palette.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Only the icon sits in the highlight capsule; the label stays
            // below it.
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 64,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? palette.bgAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
              ),
              child: Icon(item.icon, size: 24, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: context.gatesText.caption.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
