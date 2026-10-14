import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_dashboard/common/widgets/state_message.dart';
import 'package:hospital_dashboard/common/widgets/surface_card.dart';
import 'package:hospital_dashboard/features/auth/presentation/auth_controller.dart';
import 'package:hospital_dashboard/features/clinic/data/clinic_store.dart';
import 'package:hospital_dashboard/features/clinic/presentation/clinic_providers.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';
import 'package:hospital_dashboard/theme/app_theme.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(notificationFeedProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notifications', style: AppType.title),
                    SizedBox(height: 6),
                    Text(
                      'In-app alerts update while this screen is open.',
                      style: AppType.body,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  final store = await ref.read(clinicStoreProvider.future);
                  await store.markAllNotificationsRead(
                    ref.read(authControllerProvider).actor,
                  );
                },
                child: const Text('Mark all read'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: feed.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => StateMessage(
                icon: Icons.notifications_off_outlined,
                title: 'Notifications unavailable',
                message: error.toString(),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const StateMessage(
                    icon: Icons.notifications_none_rounded,
                    title: 'No notifications',
                    message:
                        'Registration, assignments, and messages show here.',
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final note = items[index];
                    return SurfaceCard(
                      onTap: () async {
                        final store = await ref.read(
                          clinicStoreProvider.future,
                        );
                        await store.markNotificationRead(
                          ref.read(authControllerProvider).actor,
                          note.id,
                        );
                        if (context.mounted) context.go(note.route);
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            note.isRead
                                ? Icons.notifications_none_rounded
                                : Icons.notifications_active_rounded,
                            color: note.isRead
                                ? AppColors.muted
                                : AppColors.teal,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(note.message),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('d MMM, h:mm a')
                                      .format(note.createdAt),
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!note.isRead)
                            const Text(
                              'Unread',
                              style: TextStyle(
                                color: AppColors.teal,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
