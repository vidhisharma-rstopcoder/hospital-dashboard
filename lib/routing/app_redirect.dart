import 'package:hospital_dashboard/features/auth/presentation/auth_controller.dart';
import 'package:hospital_dashboard/features/clinic/domain/clinic_models.dart';

/// Decides where a browser location should land, including refresh and back.
String? resolveRedirect({required AuthState auth, required Uri uri}) {
  final path = uri.path.isEmpty ? '/' : uri.path;
  final from = uri.queryParameters['from'];

  if (!auth.ready) {
    if (path == '/boot') return null;
    final remembered = (from != null && from.isNotEmpty)
        ? from
        : uri.toString();
    return '/boot?from=${Uri.encodeComponent(remembered)}';
  }

  if (!auth.authenticated) {
    if (path == '/login') return null;
    final remembered = path == '/boot' && from != null && from.isNotEmpty
        ? from
        : uri.toString();
    final destination = safeReturnPath(remembered);
    if (destination == null) return '/login';
    return '/login?from=${Uri.encodeComponent(destination)}';
  }

  if (path == '/login' || path == '/boot' || path == '/') {
    return safeReturnPath(from) ?? '/dashboard';
  }
  if (auth.role != UserRole.admin &&
      (path == '/patients/new' || path == '/doctors/new')) {
    return '/dashboard';
  }
  if (auth.role == UserRole.patient &&
      (path.startsWith('/doctors') || path.endsWith('/edit'))) {
    return '/dashboard';
  }
  if (auth.role == UserRole.doctor &&
      path.startsWith('/doctors/') &&
      path.endsWith('/edit') &&
      auth.doctorId != null &&
      !path.contains('/${auth.doctorId}/')) {
    return '/dashboard';
  }
  return null;
}

/// Staff can only be returned to an in-app path.
String? safeReturnPath(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.contains('://') || raw.startsWith('//') || !raw.startsWith('/')) {
    return null;
  }
  final uri = Uri.tryParse(raw);
  if (uri == null) return null;
  final path = uri.path;
  if (path.isEmpty || path == '/' || path == '/login' || path == '/boot') {
    return null;
  }
  return raw;
}
