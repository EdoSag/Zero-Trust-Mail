import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_trust_core/zero_trust_core.dart';
import 'package:zerotrust_mail/ui/home_page.dart';

import 'support/app.dart';

void main() {
  testWidgets('Hebrew: right to left, translated, nothing overflows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(const HomePage(), locale: ZtLanguages.hebrew));
    await tester.pumpAndSettle();
    expect(find.text('הוסיפו את חשבון הדואר הראשון'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(HomePage))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('הוספת חשבון'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'כתובת אימייל'),
      'dana@gmail.com',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Gmail דורש סיסמת אפליקציה'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('שמירה'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // With an account, in a list: the address stays readable left to right.
    await tester.pumpWidget(
      app(
        const HomePage(),
        locale: ZtLanguages.hebrew,
        accounts: [work],
        secrets: {'a1': 'pw'},
        key: const ValueKey('second'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('חשבונות דואר'), findsOneWidget);
    final title = tester.getRect(find.text('Dana Levi'));
    final icon = tester.getRect(find.byIcon(Icons.alternate_email));
    expect(icon.left, greaterThan(title.right));
    expect(tester.takeException(), isNull);
  });
}
