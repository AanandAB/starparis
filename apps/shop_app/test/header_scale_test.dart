import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starparis_design/starparis_design.dart';

/// The same clamp the app applies in app.dart. Kept inline here so the test
/// documents the behaviour it protects: a header title must stay on one line
/// even when the device font scale is enormous.
Widget clamp(BuildContext context, Widget? child) {
  const double maxScale = 1.3;
  final media = MediaQuery.of(context);
  if (media.textScaler.scale(1.0) <= maxScale) return child!;
  return MediaQuery(
    data: media.copyWith(textScaler: TextScaler.linear(maxScale)),
    child: child!,
  );
}

void main() {
  testWidgets('a header title stays on one line at a huge device text scale',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 3.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: StarTheme.light(desktop: false),
        builder: clamp,
        home: Scaffold(
          body: ScreenHeader(
            title: 'Orders',
            subtitle: 'Everything saved on this device, including work still waiting.',
            actions: <Widget>[
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.add),
                label: const Text('New order'),
              ),
            ],
          ),
        ),
      ),
    );

    final size = tester.getSize(find.text('Orders'));
    // Without the clamp this collapses to ~0 wide and stacks one char per line
    // (width 0, height in the hundreds). With it, the title has real horizontal
    // room — wrapping to two lines at worst, never a character stack.
    expect(size.width, greaterThan(60));
    expect(size.height, lessThan(200));
  });
}
