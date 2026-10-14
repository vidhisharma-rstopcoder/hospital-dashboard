import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_dashboard/common/breakpoints.dart';
import 'package:hospital_dashboard/common/widgets/hospital_logo.dart';
import 'package:hospital_dashboard/common/widgets/mesh_backdrop.dart';
import 'package:hospital_dashboard/features/auth/presentation/auth_controller.dart';
import 'package:hospital_dashboard/features/clinic/domain/clinic_models.dart';
import 'package:hospital_dashboard/features/clinic/presentation/clinic_providers.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';
import 'package:hospital_dashboard/theme/app_theme.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < Breakpoints.mobile;
    final isDesktop = width >= Breakpoints.desktop;
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.canvas,
      drawer: isMobile
          ? Drawer(
              backgroundColor: AppColors.night,
              width: 292,
              child: _Sidebar(
                extended: true,
                email: auth.email,
                onNavigate: () => _scaffoldKey.currentState?.closeDrawer(),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) _Sidebar(extended: isDesktop, email: auth.email),
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(child: MeshBackdrop()),
                Column(
                  children: [
                    if (isMobile)
                      const _MobileBar()
                    else
                      _TopBar(email: auth.email),
                    Expanded(child: widget.child),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileBar extends StatelessWidget {
  const _MobileBar();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            border: const Border(bottom: BorderSide(color: AppColors.line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Open navigation',
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded),
              ),
              const HospitalLogo(size: 30),
              const SizedBox(width: 10),
              const Text(
                'Rounds',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatefulWidget {
  const _TopBar({required this.email});

  final String? email;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _go() {
    final query = _search.text.trim();
    final path = query.isEmpty
        ? '/patients'
        : '/patients?q=${Uri.encodeQueryComponent(query)}';
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: TextField(
                controller: _search,
                onSubmitted: (_) => _go(),
                decoration: const InputDecoration(
                  hintText: 'Search a patient name or ID',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.canvas,
                ),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.go('/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.mint,
            child: Text(
              (widget.email ?? 'R').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppColors.teal,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.email ?? 'Staff',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({
    required this.extended,
    required this.email,
    this.onNavigate,
  });

  final bool extended;
  final String? email;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final width = extended ? 252.0 : 80.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: onNavigate == null ? width : double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.night,
        border: Border(right: BorderSide(color: Color(0xFF1C1F27))),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: extended ? 14 : 10,
            vertical: 18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BrandLockup(extended: extended),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final item in _destinations(
                      ref.watch(authControllerProvider).role,
                    )) ...[
                      _NavButton(
                        extended: extended,
                        label: item.label,
                        icon: item.icon,
                        selected:
                            location == item.path ||
                            (item.path != '/dashboard' &&
                                location.startsWith(item.path)),
                        badge: item.path == '/notifications'
                            ? ref
                                  .watch(notificationFeedProvider)
                                  .maybeWhen(
                                    data: (notes) => notes
                                        .where((note) => !note.isRead)
                                        .length,
                                    orElse: () => 0,
                                  )
                            : 0,
                        onTap: () {
                          onNavigate?.call();
                          context.go(item.path);
                        },
                      ),
                      const SizedBox(height: 4),
                    ],
                    const SizedBox(height: 12),
                    if (extended)
                      _StaffCard(
                        email: email,
                        role: ref.watch(authControllerProvider).role,
                      ),
                    const SizedBox(height: 8),
                    _SignOutButton(
                      extended: extended,
                      onPressed: () => _confirmSignOut(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss sign out',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondary) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(curved),
            child: AlertDialog(
              title: const Text('Sign out?'),
              content: const Text(
                'You will need your staff email and password to sign in again.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Stay'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirmed != true) return;
    await ref.read(authControllerProvider.notifier).signOut();
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}

List<_NavItem> _destinations(UserRole role) {
  return [
    const _NavItem('Dashboard', Icons.space_dashboard_rounded, '/dashboard'),
    const _NavItem('Patients', Icons.personal_injury_outlined, '/patients'),
    if (role != UserRole.patient)
      const _NavItem('Doctors', Icons.medical_services_outlined, '/doctors'),
    const _NavItem('Appointments', Icons.event_note_rounded, '/appointments'),
    const _NavItem('Messages', Icons.chat_bubble_outline_rounded, '/messages'),
    const _NavItem(
      'Notifications',
      Icons.notifications_none_rounded,
      '/notifications',
    ),
  ];
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const HospitalLogo(size: 36),
        if (extended) ...[
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rounds',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'City Hospital',
                  style: TextStyle(
                    color: Color(0xFF9AA3B2),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _NavButton extends StatefulWidget {
  const _NavButton({
    required this.extended,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final bool extended;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final extended = widget.extended;
    final button = Semantics(
      button: true,
      selected: selected,
      label: widget.label,
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: extended ? 12 : 0,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.teal
                    : _hover
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: extended
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  if (extended)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        width: 3,
                        height: 16,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFA5B4FC)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  Badge(
                    isLabelVisible: widget.badge > 0,
                    label: Text('${widget.badge}'),
                    child: Icon(
                      widget.icon,
                      color: selected ? Colors.white : const Color(0xFFB7C0CC),
                      size: 20,
                    ),
                  ),
                  if (extended) ...[
                    const SizedBox(width: 10),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (extended) return button;
    return Tooltip(message: widget.label, child: button);
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.email, required this.role});

  final String? email;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.teal,
            child: Text(
              'AM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  switch (role) {
                    UserRole.admin => 'Admin',
                    UserRole.doctor => 'Doctor',
                    UserRole.patient => 'Patient',
                  },
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  email ?? 'Staff session',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9AA3B2),
                    fontSize: 11.5,
                    fontFamily: appFontFamily,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.extended, required this.onPressed});

  final bool extended;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (!extended) {
      return IconButton(
        tooltip: 'Sign out',
        onPressed: onPressed,
        icon: const Icon(Icons.logout_rounded, color: Color(0xFFE5E7EB)),
      );
    }
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFE5E7EB),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text('Sign out'),
    );
  }
}
