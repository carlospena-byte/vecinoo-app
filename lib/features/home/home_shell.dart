import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/gates_svg_icon.dart';
import '../amenities/presentation/bookings_list_screen.dart';
import '../incidents/presentation/incidents_list_screen.dart';
import '../visits/presentation/visits_list_screen.dart';
import 'presentation/home_screen.dart';

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

  final HomeTabRequest? tabRequest;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.tabRequest?.index ?? 0;

  @override
  void didUpdateWidget(HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final request = widget.tabRequest;
    if (request != null && !identical(request, oldWidget.tabRequest)) {
      _index = request.index;
    }
  }

  void _goToTab(int index) => setState(() => _index = index);

  late final List<Widget> _screens = [
    HomeScreen(onNavigateToTab: _goToTab),
    const IncidentsListScreen(),
    const BookingsListScreen(),
    const VisitsListScreen(),
  ];

  static const _destinations = [
    _NavItem(icon: 'assets/icons/home/nav_home.svg', label: 'Inicio'),
    _NavItem(icon: 'assets/icons/home/nav_incidents.svg', label: 'Incidencias'),
    _NavItem(icon: 'assets/icons/home/nav_reservations.svg', label: 'Reservas'),
    _NavItem(icon: 'assets/icons/home/nav_visits.svg', label: 'Visitas'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      // Bottom nav labels are short and the pill has fixed height, so it
      // ignores the system's text-scale setting (like Material's own
      // NavigationBar) instead of overflowing under larger accessibility
      // font sizes.
      bottomNavigationBar: MediaQuery.withNoTextScaling(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          // Frosted glass: the pill blurs whatever scrolls under it and adds a
          // translucent white wash. The shadow sits on an outer box because
          // ClipRRect would cut it off.
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: context.palette.shadow,
                  offset: Offset(0, 8),
                  blurRadius: 24,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 72,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.palette.navGlass,
                    borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
                    border: Border.all(color: context.palette.navGlassBorder),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < _destinations.length; i++)
                        Expanded(
                          child: _NavPillItem(
                            item: _destinations[i],
                            selected: i == _index,
                            onTap: () => _goToTab(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final String icon;
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
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? context.palette.bgAccent : Colors.transparent,
        // The selected tab is outlined (invisible in light mode) so it never
        // relies on its fill alone to stand out.
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? context.palette.borderSelected
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                GatesSvgIcon(item.icon, size: 24),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: context.gatesText.caption.copyWith(
                    color: context.palette.textPrimary,
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
