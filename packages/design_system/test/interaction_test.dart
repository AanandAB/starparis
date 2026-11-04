import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starparis_design/starparis_design.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: StarTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

/// The interaction layer: the four components that give the app its feel.
/// Each is pumped in a themed tree so the test proves it renders and behaves,
/// not just that it compiles.
void main() {
  testWidgets('PressableCard fires its tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        PressableCard(onTap: () => tapped = true, child: const Text('Tile')),
      ),
    );

    await tester.tap(find.text('Tile'));
    expect(tapped, isTrue);
  });

  testWidgets('PressableCard honours a disabled card by not tapping', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        PressableCard(
          enabled: false,
          onTap: () => tapped = true,
          child: const Text('Locked'),
        ),
      ),
    );

    await tester.tap(find.text('Locked'));
    expect(tapped, isFalse);
  });

  testWidgets('AnimatedCount shows the value and settles on the new one', (
    tester,
  ) async {
    var value = 122;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedCount(
                value: value,
                format: (v) => v.toString(),
                style: Theme.of(context).textTheme.displayMedium,
              ),
              TextButton(
                onPressed: () => setState(() => value = 130),
                child: const Text('bump'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('122'), findsOneWidget);

    await tester.tap(find.text('bump'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('130'), findsOneWidget);
  });

  testWidgets('GlassPanel renders its child', (tester) async {
    await tester.pumpWidget(_wrap(const GlassPanel(child: Text('Top bar'))));
    expect(find.text('Top bar'), findsOneWidget);
  });

  testWidgets('ShortcutChip renders its label', (tester) async {
    await tester.pumpWidget(_wrap(const ShortcutChip(label: 'Ctrl K')));
    expect(find.text('Ctrl K'), findsOneWidget);
  });
}
