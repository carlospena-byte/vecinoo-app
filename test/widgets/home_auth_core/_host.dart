import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/pump_app.dart';

/// [pumpApp] with the widget inside a Scaffold (Material ancestor).
Future<void> pumpHosted(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  ThemeMode mode = ThemeMode.light,
  Map<String, Widget Function(GoRouterState state)> routes = const {},
  List<String>? visited,
  bool settle = true,
}) => pumpApp(
  tester,
  Scaffold(body: child),
  overrides: overrides,
  mode: mode,
  routes: routes,
  visited: visited,
  settle: settle,
);
