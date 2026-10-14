import 'package:hospital_dashboard/features/auth/data/tab_session_io.dart'
    if (dart.library.js_interop) 'package:hospital_dashboard/features/auth/data/tab_session_web.dart'
    as impl;

/// Per-tab sign-in on web (sessionStorage), SharedPreferences elsewhere.
/// That lets Anil stay signed in in one browser tab while Rahul uses another.
Future<String?> readTabSessionEmail() => impl.readTabSessionEmail();

Future<void> writeTabSessionEmail(String email) =>
    impl.writeTabSessionEmail(email);

Future<void> clearTabSessionEmail() => impl.clearTabSessionEmail();
