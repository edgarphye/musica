import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:musica/src/ui/app.dart';

void main() {
  testWidgets('La app se monta y muestra la pantalla de explorar',
      (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(child: const MusicaApp()));
    await tester.pumpAndSettle();

    expect(find.text('Mi música'), findsOneWidget);
    expect(find.text('Convertir música'), findsNothing);
  });

  testWidgets('La sección Acerca de muestra los datos del autor',
      (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(child: const MusicaApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Acerca de'));
    await tester.pumpAndSettle();

    expect(find.text('Edgar Phye Parga'), findsOneWidget);
    expect(find.text('Ingeniero en Desarrollo de Software'), findsOneWidget);
    expect(find.text('ephye7214@gmail.com'), findsOneWidget);
    expect(find.text('13 de septiembre de 2026, 21:01 h'), findsOneWidget);
    expect(find.text('Cerrar la aplicación'), findsOneWidget);
  });

  testWidgets('El selector de temas permite cambiar de diseño de ventana',
      (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(child: const MusicaApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Acerca de'));
    await tester.pumpAndSettle();

    expect(find.text('Lavanda'), findsOneWidget);
    expect(find.text('Onyx'), findsOneWidget);
    expect(find.text('Esmeralda'), findsOneWidget);
    expect(find.text('Vino'), findsOneWidget);

    await tester.ensureVisible(find.text('Vino'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vino'));
    await tester.pumpAndSettle();

    final material = tester.element(find.byType(MaterialApp));
    final app = material.widget as MaterialApp;
    expect(app.theme!.brightness, Brightness.dark);
  });
}