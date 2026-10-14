import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_dashboard/theme/app_theme.dart';
import 'package:hospital_dashboard/features/auth/presentation/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login form explains invalid email and password', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light(), home: const LoginPage()),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('email-field')),
      'not-an-email',
    );
    await tester.enterText(find.byKey(const Key('password-field')), 'short');
    await tester.tap(find.byKey(const Key('sign-in-button')));
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
  });
}
