import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_dashboard/routing/app_redirect.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';
import 'package:hospital_dashboard/theme/app_theme.dart';
import 'package:hospital_dashboard/common/widgets/app_shell.dart';
import 'package:hospital_dashboard/common/widgets/hospital_logo.dart';
import 'package:hospital_dashboard/common/widgets/mesh_backdrop.dart';
import 'package:hospital_dashboard/features/auth/presentation/auth_controller.dart';
import 'package:hospital_dashboard/features/auth/presentation/boot_page.dart';
import 'package:hospital_dashboard/features/auth/presentation/login_page.dart';
import 'package:hospital_dashboard/features/dashboard/presentation/dashboard_page.dart';
import 'package:hospital_dashboard/features/appointments/presentation/appointments_page.dart';
import 'package:hospital_dashboard/features/chat/presentation/messages_page.dart';
import 'package:hospital_dashboard/features/doctors/presentation/doctor_form_page.dart';
import 'package:hospital_dashboard/features/doctors/presentation/doctor_profile_page.dart';
import 'package:hospital_dashboard/features/doctors/presentation/doctors_page.dart';
import 'package:hospital_dashboard/features/notifications/presentation/notifications_page.dart';
import 'package:hospital_dashboard/features/patients/presentation/patient_details_page.dart';
import 'package:hospital_dashboard/features/patients/presentation/patient_form_page.dart';
import 'package:hospital_dashboard/features/patients/presentation/patients_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: refresh,
    redirect: (context, state) {
      return resolveRedirect(
        auth: ref.read(authControllerProvider),
        uri: state.uri,
      );
    },
    errorBuilder: (context, state) =>
        NotFoundPage(location: state.uri.toString()),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/dashboard'),
      GoRoute(
        path: '/boot',
        pageBuilder: (context, state) => _fade(state, const BootPage()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fade(state, const LoginPage()),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                _fade(state, const DashboardPage()),
          ),
          GoRoute(
            path: '/patients',
            pageBuilder: (context, state) => _fade(state, const PatientsPage()),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) =>
                    _fade(state, const PatientFormPage()),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  return _fade(state, PatientDetailsPage(patientId: id));
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      return _fade(state, PatientFormPage(patientId: id));
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/doctors',
            pageBuilder: (context, state) => _fade(state, const DoctorsPage()),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (context, state) =>
                    _fade(state, const DoctorFormPage()),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _fade(
                  state,
                  DoctorProfilePage(doctorId: state.pathParameters['id']),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) => _fade(
                      state,
                      DoctorFormPage(doctorId: state.pathParameters['id']),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/appointments',
            pageBuilder: (context, state) =>
                _fade(state, const AppointmentsPage()),
          ),
          GoRoute(
            path: '/messages',
            pageBuilder: (context, state) => _fade(state, const MessagesPage()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _fade(
                  state,
                  ChatPage(conversationId: state.pathParameters['id'] ?? ''),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) =>
                _fade(state, const NotificationsPage()),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    _subscription = ref.listen<AuthState>(authControllerProvider, (
      previous,
      next,
    ) {
      notifyListeners();
    });
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({required this.location, super.key});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const MeshBackdrop(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HospitalLogo(size: 56),
                    const SizedBox(height: 18),
                    const Text(
                      'Page not found',
                      textAlign: TextAlign.center,
                      style: AppType.title,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      location,
                      textAlign: TextAlign.center,
                      style: AppType.body,
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () => context.go('/dashboard'),
                      child: const Text('Back to dashboard'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
