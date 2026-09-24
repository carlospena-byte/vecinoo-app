import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../amenities/presentation/amenities_list_screen.dart';
import '../incidents/presentation/incidents_list_screen.dart';
import '../visits/presentation/visits_list_screen.dart';
import 'presentation/home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _goToTab(int index) => setState(() => _index = index);

  late final List<Widget> _screens = [
    HomeScreen(onNavigateToTab: _goToTab),
    const IncidentsListScreen(),
    const AmenitiesListScreen(),
    const VisitsListScreen(),
  ];

  static const _destinations = [
    _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    _NavItem(
      icon: Icons.warning_amber_outlined,
      selectedIcon: Icons.warning_amber,
      label: 'Incidencias',
    ),
    _NavItem(
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
      label: 'Reservas',
    ),
    _NavItem(
      icon: Icons.person_add_alt_outlined,
      selectedIcon: Icons.person_add_alt,
      label: 'Visitas',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Container(
          height: 72,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: GatesColors.bgSurface,
            borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
            boxShadow: const [
              BoxShadow(color: Color(0x1A243026), blurRadius: 32, offset: Offset(0, 8)),
            ],
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
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.selectedIcon, required this.label});

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _NavPillItem extends StatelessWidget {
  const _NavPillItem({required this.item, required this.selected, required this.onTap});

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? GatesColors.bgAccent : Colors.transparent,
      borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: 24,
                color: GatesColors.textPrimary,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: GatesTypography.caption.copyWith(color: GatesColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
