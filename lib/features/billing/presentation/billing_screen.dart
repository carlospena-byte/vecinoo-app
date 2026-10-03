import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_paged_list.dart';
import '../../../core/widgets/gates_segmented_tabs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/l10n.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/installment.dart';
import 'billing_controller.dart';
import 'billing_format.dart';

enum _BillingTab { pending, history }

/// What the unit owes (summary + open installments) and its payment
/// history. Reached from the Home "Cobros" card.
class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key, this.startOnHistory = false});

  final bool startOnHistory;

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  late _BillingTab _tab = widget.startOnHistory
      ? _BillingTab.history
      : _BillingTab.pending;

  @override
  Widget build(BuildContext context) {
    final unitId = ref.watch(selectedMembershipProvider).value?.unitId;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(context.l10n.billingTitle),
      ),
      body: unitId == null
          ? const LoadingView()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    GatesSpacing.space24,
                    GatesSpacing.space8,
                    GatesSpacing.space24,
                    GatesSpacing.space16,
                  ),
                  child: _BalanceCard(unitId: unitId),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GatesSpacing.space24,
                  ),
                  child: GatesSegmentedTabs<_BillingTab>(
                    options: [
                      GatesSegmentedTabOption(
                        value: _BillingTab.pending,
                        label: context.l10n.billingTabPending,
                      ),
                      GatesSegmentedTabOption(
                        value: _BillingTab.history,
                        label: context.l10n.billingTabHistory,
                      ),
                    ],
                    selected: _tab,
                    onSelect: (tab) => setState(() => _tab = tab),
                  ),
                ),
                Expanded(
                  child: _tab == _BillingTab.pending
                      ? _PendingList(unitId: unitId)
                      : _HistoryList(unitId: unitId),
                ),
              ],
            ),
    );
  }
}

EdgeInsets _listPadding(BuildContext context) => EdgeInsets.fromLTRB(
  GatesSpacing.space24,
  GatesSpacing.space16,
  GatesSpacing.space24,
  GatesSpacing.space24 + MediaQuery.paddingOf(context).bottom,
);

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(billingBalanceProvider(unitId)).value;
    final palette = context.palette;
    final overdue = balance?.hasOverdue ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: palette.bgBrand,
        borderRadius: BorderRadius.circular(GatesRadius.radius24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.billingBalanceLabel,
            style: context.gatesText.caption.copyWith(
              color: palette.textOnBrand,
            ),
          ),
          const SizedBox(height: GatesSpacing.space4),
          Text(
            balance == null ? '—' : formatMoney(balance.total),
            style: GatesTypography.headingLarge.copyWith(
              color: palette.textOnBrand,
            ),
          ),
          if (balance != null) ...[
            const SizedBox(height: GatesSpacing.space4),
            Text(
              balance.isSettled
                  ? context.l10n.billingAllCaughtUp
                  : overdue
                  ? context.l10n.billingOverdueSummary(
                      balance.overdueCount,
                      formatMoney(balance.overdue),
                    )
                  : context.l10n.homeBillingUpcoming,
              style: GatesTypography.label.copyWith(color: palette.textOnBrand),
            ),
          ],
        ],
      ),
    );
  }
}

class _PendingList extends ConsumerWidget {
  const _PendingList({required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(openInstallmentsProvider(unitId));
    return open.when(
      loading: () => const LoadingView(),
      error: (_, _) => ErrorView(
        message: context.l10n.billingLoadError,
        onRetry: () => ref.invalidate(openInstallmentsProvider(unitId)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyView(
            message: context.l10n.billingEmptyPending,
            icon: TablerIcons.receipt,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(openInstallmentsProvider(unitId));
            await ref.read(openInstallmentsProvider(unitId).future);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: _listPadding(context),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: GatesSpacing.space12),
            itemBuilder: (context, i) => InstallmentCard(installment: items[i]),
          ),
        );
      },
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paging = ref.watch(billingHistoryProvider(unitId));
    final controller = ref.read(billingHistoryProvider(unitId).notifier);

    if (paging.items.isEmpty) {
      if (paging.failure != null) {
        return ErrorView(
          message: context.l10n.billingLoadError,
          onRetry: controller.refresh,
        );
      }
      if (paging.loading) return const LoadingView();
      return EmptyView(
        message: context.l10n.billingEmptyHistory,
        icon: TablerIcons.receipt,
      );
    }
    return GatesPagedList<Installment>(
      items: paging.items,
      state: paging,
      onLoadMore: controller.loadMore,
      onRefresh: controller.refresh,
      padding: _listPadding(context),
      itemBuilder: (context, installment) =>
          InstallmentCard(installment: installment),
    );
  }
}

class InstallmentCard extends StatelessWidget {
  const InstallmentCard({super.key, required this.installment});

  final Installment installment;

  @override
  Widget build(BuildContext context) {
    final i = installment;
    final l10n = context.l10n;
    final palette = context.palette;
    final amount = i.isOpen ? i.balance : i.totalDue;

    final detail = switch (i.status) {
      InstallmentStatus.paid when i.paidAt != null => l10n.billingPaidOn(
        formatBillingDay(i.paidAt!),
      ),
      InstallmentStatus.cancelled => null,
      _ => l10n.billingDueOn(formatBillingDay(i.dueDate)),
    };

    final semanticsLabel = [
      i.chargeName,
      if (i.isBooking) l10n.billingSourceBooking,
      formatBillingMonth(i.period),
      formatMoney(amount),
      _statusLabel(l10n, i),
    ].join(', ');

    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(GatesSpacing.space16),
        decoration: BoxDecoration(
          color: palette.bgSurface,
          border: Border.all(color: palette.borderDefault),
          borderRadius: BorderRadius.circular(GatesRadius.radius16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i.isBooking
                            ? '${formatBillingMonth(i.period)} · ${l10n.billingSourceBooking}'
                            : formatBillingMonth(i.period),
                        style: context.gatesText.caption,
                      ),
                      const SizedBox(height: GatesSpacing.space4),
                      Text(
                        i.chargeName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GatesTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: GatesSpacing.space12),
                Text(
                  formatMoney(amount),
                  style: GatesTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: GatesSpacing.space12),
            Wrap(
              spacing: GatesSpacing.space12,
              runSpacing: GatesSpacing.space8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _StatusChip(installment: i),
                if (detail != null)
                  Text(detail, style: context.gatesText.labelSecondary),
              ],
            ),
            if (i.isOpen && i.paidAmount > 0) ...[
              const SizedBox(height: GatesSpacing.space8),
              Text(
                l10n.billingPaidSoFar(formatMoney(i.paidAmount)),
                style: context.gatesText.caption,
              ),
            ],
            if (i.lateFee > 0 && i.status != InstallmentStatus.cancelled) ...[
              const SizedBox(height: GatesSpacing.space4),
              Text(
                l10n.billingLateFee(formatMoney(i.lateFee)),
                style: context.gatesText.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _statusLabel(AppLocalizations l10n, Installment i) {
  if (i.isOpen && i.isOverdue) return l10n.billingStatusOverdue(i.daysOverdue);
  return switch (i.status) {
    InstallmentStatus.pending => l10n.billingStatusPending,
    InstallmentStatus.partial => l10n.billingStatusPartial,
    InstallmentStatus.paid => l10n.billingStatusPaid,
    InstallmentStatus.cancelled => l10n.billingStatusCancelled,
  };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.installment});

  final Installment installment;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final i = installment;
    final (Color fg, Color bg) = i.isOpen && i.isOverdue
        ? (palette.statusError, palette.statusErrorBg)
        : switch (i.status) {
            InstallmentStatus.paid => (
              palette.statusSuccess,
              palette.statusSuccessBg,
            ),
            InstallmentStatus.partial => (
              palette.statusWarning,
              palette.statusWarningBg,
            ),
            InstallmentStatus.cancelled => (
              palette.textSecondary,
              palette.bgSubtle,
            ),
            InstallmentStatus.pending => (palette.textBrand, palette.bgAccent),
          };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GatesSpacing.space12,
        vertical: GatesSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
      ),
      child: Text(
        _statusLabel(context.l10n, i),
        style: context.gatesText.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
