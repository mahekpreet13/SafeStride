import 'package:flutter/material.dart';
import 'pages/navigation_page.dart';
import 'pages/placeholder_page.dart';
import 'pages/settings_page.dart';

class NavScreenConfig {
  final String route;
  final String label;
  final IconData icon;
  final Widget Function() builder;
  final bool inNavBar;

  const NavScreenConfig({
    required this.route,
    required this.label,
    required this.icon,
    required this.builder,
    this.inNavBar = false,
  });
}

final List<NavScreenConfig> navScreens = [
  NavScreenConfig(
    route: '/placeholder',
    label: 'Placeholder',
    icon: Icons.help_outline,
    builder: () => const PlaceholderPage(),
    inNavBar: true,
  ),
  NavScreenConfig(
    route: '/navigation',
    label: 'Navigation',
    icon: Icons.navigation,
    builder: () => const NavigationPage(),
    inNavBar: true,
  ),
  NavScreenConfig(
    route: '/settings',
    label: 'Settings',
    icon: Icons.settings,
    builder: () => const SettingsPage(),
    inNavBar: true,
  ),
];
