import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';
import 'package:hospital_dashboard/theme/app_theme.dart';
import 'package:hospital_dashboard/features/auth/presentation/auth_controller.dart';
import 'package:hospital_dashboard/features/clinic/domain/clinic_models.dart';
import 'package:hospital_dashboard/common/widgets/entrance.dart';
import 'package:hospital_dashboard/common/widgets/shimmer_box.dart';
import 'package:hospital_dashboard/common/widgets/state_message.dart';
import 'package:hospital_dashboard/common/widgets/surface_card.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_exception.dart';
import 'package:hospital_dashboard/features/patients/domain/patient_status.dart';
import 'package:hospital_dashboard/features/patients/presentation/patient_providers.dart';
import 'package:hospital_dashboard/features/patients/presentation/widgets/patient_cards.dart';
import 'package:hospital_dashboard/features/patients/presentation/widgets/patient_pager.dart';
import 'package:hospital_dashboard/features/patients/presentation/widgets/patient_table.dart';

class PatientsPage extends ConsumerStatefulWidget {
  const PatientsPage({super.key});

  @override
  ConsumerState<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends ConsumerState<PatientsPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  String? _appliedQuery;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query = GoRouterState.of(context).uri.queryParameters['q'] ?? '';
    if (_appliedQuery == query) return;
    _appliedQuery = query;
    if (_search.text != query) {
      _search.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      _appliedQuery = value.trim();
      _go(search: value.trim(), page: 1);
    });
  }

  void _go({String? search, String? status, int? page}) {
    final params = GoRouterState.of(context).uri.queryParameters;
    final nextSearch = search ?? params['q'] ?? '';
    final nextStatus = status ?? params['status'] ?? 'All';
    final nextPage = page ?? int.tryParse(params['page'] ?? '') ?? 1;
    final query = <String, String>{
      if (nextSearch.isNotEmpty) 'q': nextSearch,
      if (nextStatus.isNotEmpty && nextStatus != 'All') 'status': nextStatus,
      if (nextPage > 1) 'page': '$nextPage',
    };
    final uri = Uri(
      path: '/patients',
      queryParameters: query.isEmpty ? null : query,
    );
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final query = queryFromUri(uri);
    final result = ref.watch(patientListProvider(query));
    final statusValue = query.status?.label ?? 'All';
    final total = result.value?.total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Entrance(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ward list', style: AppType.title),
                      SizedBox(height: 6),
                      Text('Name or ID.', style: AppType.body),
                    ],
                  ),
                ),
                if (ref.watch(authControllerProvider).role == UserRole.admin)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilledButton(
                      onPressed: () => context.go('/patients/new'),
                      child: const Text('Add patient'),
                    ),
                  ),
                if (total != null) _TotalPill(total: total),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Entrance(
            delay: const Duration(milliseconds: 40),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 720;
                final search = TextField(
                  controller: _search,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search name or ID',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _search.clear();
                              _appliedQuery = '';
                              _go(search: '', page: 1);
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                );
                final filter = _StatusFilters(
                  selected: statusValue,
                  onSelected: (value) => _go(status: value, page: 1),
                );
                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [search, const SizedBox(height: 10), filter],
                  );
                }
                return Row(
                  children: [
                    Expanded(flex: 3, child: search),
                    const SizedBox(width: 12),
                    Flexible(flex: 4, child: filter),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: result.when(
              loading: () => const _ListSkeleton(),
              error: (error, _) => StateMessage(
                icon: Icons.cloud_off_rounded,
                title: 'Could not load patients',
                message: error is PatientApiException
                    ? error.message
                    : 'The patient list could not be loaded.',
                actionLabel: 'Try again',
                onAction: () => ref.invalidate(patientListProvider(query)),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  final filtered =
                      query.search.isNotEmpty || query.status != null;
                  return StateMessage(
                    icon: filtered
                        ? Icons.search_off_rounded
                        : Icons.inbox_outlined,
                    title: filtered
                        ? 'No matching patients'
                        : 'No patients yet',
                    message: filtered
                        ? 'No patient matches that name, ID, or status.'
                        : 'There are no patients on file.',
                    actionLabel: filtered ? 'Clear filters' : null,
                    onAction: filtered
                        ? () {
                            _search.clear();
                            _appliedQuery = '';
                            context.go('/patients');
                          }
                        : null,
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final table = constraints.maxWidth >= 860;
                    return SurfaceCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          Expanded(
                            child: table
                                ? ListView(
                                    children: [
                                      PatientTable(
                                        patients: page.items,
                                        onOpen: (patient) => context.push(
                                          '/patients/${patient.id}',
                                        ),
                                      ),
                                    ],
                                  )
                                : PatientCards(
                                    patients: page.items,
                                    onOpen: (patient) =>
                                        context.push('/patients/${patient.id}'),
                                  ),
                          ),
                          const Divider(height: 1, color: AppColors.line),
                          PatientPager(
                            page: page.page,
                            total: page.total,
                            pageSize: page.pageSize,
                            onPage: (next) => _go(page: next),
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

class _TotalPill extends StatelessWidget {
  const _TotalPill({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(total),
      tween: Tween(begin: 0, end: total.toDouble()),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.line),
          ),
          child: Text(
            '${value.round()} on file',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        );
      },
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = [
      'All',
      for (final status in PatientStatus.values) status.label,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options) ...[
            _StatusChipButton(
              label: option == 'All'
                  ? 'All'
                  : option == 'Observation'
                  ? 'Under Observation'
                  : option,
              selected: selected == option,
              onTap: () => onSelected(option),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _StatusChipButton extends StatefulWidget {
  const _StatusChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_StatusChipButton> createState() => _StatusChipButtonState();
}

class _StatusChipButtonState extends State<_StatusChipButton> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.ink
                : _hover
                ? AppColors.mint
                : AppColors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.line,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SurfaceCard(
      child: Column(
        children: [
          ShimmerBox(height: 18),
          SizedBox(height: 16),
          ShimmerBox(height: 48),
          SizedBox(height: 12),
          ShimmerBox(height: 48),
          SizedBox(height: 12),
          ShimmerBox(height: 48),
          SizedBox(height: 12),
          ShimmerBox(height: 48),
        ],
      ),
    );
  }
}
