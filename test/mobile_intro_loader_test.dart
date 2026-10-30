import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:post_manager/core/presentation/mobile_intro_loader.dart';

void main() {
  testWidgets('shows the 10-second intro on mobile widths', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: MobileIntroLoader(child: Text('App content'))),
    );

    expect(find.text('PREPARING YOUR WORKSPACE'), findsOneWidget);
    await tester.pump(const Duration(seconds: 9));
    expect(find.text('PREPARING YOUR WORKSPACE'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('PREPARING YOUR WORKSPACE'), findsNothing);
  });

  testWidgets('skips the intro on desktop widths', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: MobileIntroLoader(child: Text('App content'))),
    );

    expect(find.text('PREPARING YOUR WORKSPACE'), findsNothing);
    expect(find.text('App content'), findsOneWidget);
  });
}
