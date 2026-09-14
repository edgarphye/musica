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
}