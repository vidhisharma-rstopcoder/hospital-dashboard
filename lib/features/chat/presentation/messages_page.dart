import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_dashboard/common/widgets/state_message.dart';
import 'package:hospital_dashboard/common/widgets/surface_card.dart';
import 'package:hospital_dashboard/features/auth/presentation/auth_controller.dart';
import 'package:hospital_dashboard/features/clinic/data/clinic_store.dart';
import 'package:hospital_dashboard/features/clinic/domain/clinic_models.dart';
import 'package:hospital_dashboard/features/clinic/presentation/clinic_providers.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';
import 'package:hospital_dashboard/theme/app_theme.dart';
import 'package:intl/intl.dart';

class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(_threadsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Messages', style: AppType.title),
          const SizedBox(height: 6),
          const Text(
            'Open Anil in one tab and Rahul in another to see replies live. Chat only works after a doctor is assigned.',
            style: AppType.body,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: threads.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => StateMessage(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Messages unavailable',
                message: error.toString(),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const StateMessage(
                    icon: Icons.forum_outlined,
                    title: 'No conversations',
                    message: 'Assign a doctor before starting a chat.',
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final thread = items[index];
                    return SurfaceCard(
                      onTap: () async {
                        final store = await ref.read(
                          clinicStoreProvider.future,
                        );
                        final actor = ref.read(authControllerProvider).actor;
                        final conversation = await store.openConversation(
                          actor,
                          patientId: thread.patientId,
                          doctorId: thread.doctorId,
                        );
                        if (context.mounted) {
                          context.go('/messages/${conversation.id}');
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.chat_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              thread.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
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

class _Thread {
  const _Thread({
    required this.patientId,
    required this.doctorId,
    required this.label,
  });

  final int patientId;
  final String doctorId;
  final String label;
}

final _threadsProvider = FutureProvider.autoDispose<List<_Thread>>((ref) async {
  final store = await ref.watch(clinicStoreProvider.future);
  final auth = ref.watch(authControllerProvider);
  final subscription = store.changes.listen((_) => ref.invalidateSelf());
  ref.onDispose(subscription.cancel);
  final actor = auth.actor;
  if (actor.role == UserRole.patient && actor.patientId != null) {
    final rel = await store.activeRelationship(actor.patientId!);
    if (rel == null) return const [];
    final doctor = await store.getDoctor(actor, rel.doctorId);
    return [
      _Thread(
        patientId: rel.patientId,
        doctorId: rel.doctorId,
        label: doctor.name,
      ),
    ];
  }
  final patients = actor.role == UserRole.doctor && actor.doctorId != null
      ? await store.patientsForDoctor(actor, actor.doctorId!)
      : await store.visiblePatients(actor);
  final rels = <_Thread>[];
  for (final patient in patients) {
    final rel = await store.activeRelationship(patient.id);
    if (rel == null) continue;
    rels.add(
      _Thread(
        patientId: patient.id,
        doctorId: rel.doctorId,
        label: '${patient.name} · ${rel.doctorId}',
      ),
    );
  }
  return rels;
});

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({required this.conversationId, super.key});

  final String conversationId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  var _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    final store = await ref.read(clinicStoreProvider.future);
    await store.markConversationRead(
      ref.read(authControllerProvider).actor,
      widget.conversationId,
    );
  }

  Future<void> _send() async {
    final body = _text.text;
    if (body.trim().isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final store = await ref.read(clinicStoreProvider.future);
      await store.sendMessage(
        ref.read(authControllerProvider).actor,
        conversationId: widget.conversationId,
        text: body,
      );
      _text.clear();
      await _markRead();
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authControllerProvider).email?.toLowerCase() ?? '';
    final messages = ref.watch(chatFeedProvider(widget.conversationId));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back to messages',
                onPressed: () => context.go('/messages'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const Expanded(
                child: Text('Live conversation', style: AppType.section),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: AppColors.discharged),
                    SizedBox(width: 6),
                    Text(
                      'Live',
                      style: TextStyle(
                        color: AppColors.discharged,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: messages.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => StateMessage(
              icon: Icons.wifi_off_rounded,
              title: 'Chat unavailable',
              message: error.toString(),
              actionLabel: 'Try again',
              onAction: () =>
                  ref.invalidate(chatFeedProvider(widget.conversationId)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const StateMessage(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No messages yet',
                  message: 'Send the first message in this conversation.',
                );
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scroll.hasClients) {
                  _scroll.jumpTo(_scroll.position.maxScrollExtent);
                }
              });
              DateTime? previousDay;
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final message = items[index];
                  final day = DateTime(
                    message.createdAt.year,
                    message.createdAt.month,
                    message.createdAt.day,
                  );
                  final showDay = previousDay == null || previousDay != day;
                  previousDay = day;
                  final mine = message.senderId == me;
                  return Column(
                    children: [
                      if (showDay)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(DateFormat('d MMM yyyy').format(day)),
                        ),
                      Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 420),
                          decoration: BoxDecoration(
                            color: mine ? AppColors.teal : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: mine
                                ? null
                                : Border.all(color: AppColors.line),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal.withValues(
                                  alpha: mine ? 0.18 : 0.04,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                message.text,
                                style: TextStyle(
                                  color: mine ? Colors.white : AppColors.ink,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('h:mm a').format(message.createdAt),
                                style: TextStyle(
                                  color: mine
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : AppColors.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: 'Write a message',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _sending ? null : _send,
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
