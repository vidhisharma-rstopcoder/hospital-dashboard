import 'package:flutter/material.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';

class PatientPager extends StatelessWidget {
  const PatientPager({
    required this.page,
    required this.total,
    required this.pageSize,
    required this.onPage,
    super.key,
  });

  final int page;
  final int total;
  final int pageSize;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final totalPages = total == 0 ? 1 : (total / pageSize).ceil();
    final current = page.clamp(1, totalPages);
    final start = total == 0 ? 0 : ((current - 1) * pageSize) + 1;
    final end = total == 0 ? 0 : (current * pageSize).clamp(0, total);
    final pages = _window(current, totalPages);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text(
            'Showing $start–$end of $total',
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous page',
                enabled: current > 1,
                onTap: () => onPage(current - 1),
              ),
              for (final entry in pages)
                entry == null
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('…'),
                      )
                    : _NumberButton(
                        page: entry,
                        selected: entry == current,
                        onTap: () => onPage(entry),
                      ),
              _PageButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next page',
                enabled: current < totalPages,
                onTap: () => onPage(current + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<int?> _window(int current, int total) {
    if (total <= 7) {
      return [for (var i = 1; i <= total; i++) i];
    }
    final pages = <int?>[1];
    var start = (current - 1).clamp(2, total - 3);
    var end = (current + 1).clamp(4, total - 1);
    if (current <= 3) {
      start = 2;
      end = 4;
    } else if (current >= total - 2) {
      start = total - 3;
      end = total - 1;
    }
    if (start > 2) pages.add(null);
    for (var i = start; i <= end; i++) {
      pages.add(i);
    }
    if (end < total - 1) pages.add(null);
    pages.add(total);
    return pages;
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? onTap : null,
      icon: Icon(icon),
    );
  }
}

class _NumberButton extends StatelessWidget {
  const _NumberButton({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final int page;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? AppColors.teal : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Text(
                '$page',
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
