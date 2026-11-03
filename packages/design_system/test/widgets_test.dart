import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starparis_design/starparis_design.dart';

/// The design system's own tests. Small on purpose: they pin the things a
/// redesign breaks silently — that a stat shows its value and its label, that a
/// section header renders its count, and that a skeleton does not paint text.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: StarTheme.light(desktop: true),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('a stat tile shows the figure, the label and the hint', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 240,
          child: StarStat(
            label: 'Overdue',
            value: '3',
            hint: 'past its date',
            icon: Icons.warning_amber_outlined,
            tone: StarStatTone.danger,
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('OVERDUE'), findsOneWidget);
    expect(find.text('past its date'), findsOneWidget);
  });

  testWidgets('a section header carries its count and action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      host(
        StarSectionHeader(
          title: 'Due today',
          subtitle: 'jobs promised today',
          count: 4,
          trailing: TextButton(
            onPressed: () => tapped = true,
            child: const Text('Board'),
          ),
        ),
      ),
    );

    expect(find.text('Due today'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    await tester.tap(find.text('Board'));
    expect(tapped, isTrue);
  });

  testWidgets('the skeleton list fills the space without text', (tester) async {
    await tester.pumpWidget(host(const StarSkeletonList(rows: 3)));

    expect(find.byType(StarSkeleton), findsNWidgets(3));
    expect(find.byType(Text), findsNothing);
  });
}
