import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/l10n/l10n.dart';
import 'package:go_router/go_router.dart';

import 'fonts.dart';
import 'pump_app.dart';

void main() {
  setUpAll(loadManrope);

  testWidgets('pumpApp provides l10n, theme and routing', (tester) async {
    final visited = <String>[];
    await pumpApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => context.push('/next?x=1'),
          child: Text(context.l10n.commonRetry),
        ),
      ),
      routes: {'/next': (_) => const Text('next page')},
      visited: visited,
    );

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('next page'), findsOneWidget);
    expect(visited, ['/next?x=1']);
  });
}
