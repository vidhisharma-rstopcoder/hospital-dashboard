import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_dashboard/features/auth/presentation/auth_controller.dart';
import 'package:hospital_dashboard/features/clinic/data/clinic_store.dart';
import 'package:hospital_dashboard/features/clinic/domain/clinic_models.dart';

final clinicSummaryProvider = StreamProvider<ClinicSummary>((ref) async* {
  final store = await ref.watch(clinicStoreProvider.future);
  final auth = ref.watch(authControllerProvider);
  if (!auth.authenticated) return;
  yield await store.summary(auth.actor);
  await for (final _ in store.changes) {
    yield await store.summary(auth.actor);
  }
});

final notificationFeedProvider = StreamProvider<List<ClinicNotification>>((
  ref,
) async* {
  final store = await ref.watch(clinicStoreProvider.future);
  final auth = ref.watch(authControllerProvider);
  if (!auth.authenticated) {
    yield const [];
    return;
  }
  yield* store.watchNotifications(auth.actor);
});

final chatFeedProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, conversationId) async* {
      final store = await ref.watch(clinicStoreProvider.future);
      final auth = ref.watch(authControllerProvider);
      if (!auth.authenticated) {
        yield const [];
        return;
      }
      yield* store.watchMessages(auth.actor, conversationId);
    });
