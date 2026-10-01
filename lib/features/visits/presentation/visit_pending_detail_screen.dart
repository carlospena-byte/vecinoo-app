import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_sheet.dart';
import '../../../core/widgets/gates_text_action.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/l10n.dart';
import '../../home/home_shell.dart';
import '../../session/presentation/session_controller.dart';
import 'fastlane_link.dart';
import '../domain/visit.dart';
import 'visits_controller.dart';

/// "Hoy, 29 sept. · 2:00 p. m." — matches the Figma F02 summary card. The
/// year is only added when the visit isn't in the current year.
String _arrivalLabel(AppLocalizations l10n, DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final dayMonth =
      '${DateFormat('d MMM', 'es').format(date).replaceAll('.', '')}.';
  final year = date.year == now.year ? '' : ' ${date.year}';
  final time = DateFormat('h:mm a', 'es').format(date);
  final rest = '$dayMonth$year · $time';
  if (day == today) return l10n.visitsArrivalToday(rest);
  if (day == today.add(const Duration(days: 1))) {
    return l10n.visitsArrivalTomorrow(rest);
  }
  return rest;
}

/// FastLane invitation that is still waiting for the visitor's data — Figma
/// F02 "Invitación creada / Compartir" (node 120:718). Shown right after
/// creating an invitation and again when the resident taps a pending visit in
/// the list, with the same actions both times: share, copy the link, edit or
/// cancel.
///
/// Reads the visit from the live [visitsListProvider] stream so edits show up
/// without a refresh. [initialVisit] covers the moment right after creation,
/// before Realtime has delivered the new row to that stream.
class VisitPendingDetailScreen extends ConsumerStatefulWidget {
  const VisitPendingDetailScreen({
    super.key,
    required this.visitId,
    this.initialVisit,
    this.justCreated = false,
  });

  final String visitId;
  final Visit? initialVisit;

  /// Arrived here straight from creating the invitation: offers "Ir a mis
  /// visitas" in place of cancelling what was just created.
  final bool justCreated;

  @override
  ConsumerState<VisitPendingDetailScreen> createState() =>
      _VisitPendingDetailScreenState();
}

class _VisitPendingDetailScreenState
    extends ConsumerState<VisitPendingDetailScreen> {
  bool _isCancelling = false;

  Future<void> _copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    showGatesToast(
      context,
      type: GatesToastType.success,
      title: context.l10n.visitsPendingLinkCopied,
    );
  }

  Future<void> _share(Visit visit, String link) async {
    final residentialName = ref
        .read(selectedMembershipProvider)
        .value
        ?.residentialName;
    final l10n = context.l10n;
    final title = residentialName == null
        ? l10n.visitsPendingShareTitle
        : l10n.visitsPendingShareTitleResidential(residentialName);
    final detail = _arrivalLabel(l10n, visit.validFrom);
    // The OS share sheet (iOS/Android). iPads need an anchor rect for the
    // popover, so use this screen's bounds.
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: '$title\n$detail\n$link',
        subject: title,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _cancel(Visit visit) async {
    final confirmed = await showGatesSheet<bool>(
      context,
      (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: GatesSpacing.space24)
            .copyWith(bottom: GatesSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GatesSheetHeader(title: context.l10n.visitsPendingCancel),
            const SizedBox(height: GatesSpacing.space8),
            Text(
              context.l10n.visitsPendingCancelBody,
              style: GatesTypography.body,
            ),
            const SizedBox(height: GatesSpacing.space24),
            SizedBox(
              width: double.infinity,
              child: GatesButton(
                label: context.l10n.visitsPendingCancelConfirm,
                style: GatesButtonStyle.destructive,
                onPressed: () => Navigator.of(sheetContext).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await ref.read(visitsRepositoryProvider).cancelVisit(visit.id);
      if (!mounted) return;
      context.pop();
      showGatesToast(
        context,
        type: GatesToastType.success,
        title: context.l10n.visitsPendingCancelledToast,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      showGatesToast(
        context,
        type: GatesToastType.error,
        title: context.l10n.visitsPendingCancelError,
        message: context.l10n.visitsTryAgain,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final membership = ref.watch(selectedMembershipProvider).value;
    if (membership == null) return const Scaffold(body: LoadingView());

    final visitsAsync = ref.watch(visitsListProvider(membership.unitId));
    final fromList = visitsAsync.value
        ?.where((v) => v.id == widget.visitId)
        .firstOrNull;
    // Just created and not in the stream yet: trust the row we were handed.
    final visit = fromList ?? widget.initialVisit;

    // No longer pending (visitor registered, or it was cancelled): nothing
    // left to manage here.
    if (fromList != null &&
        fromList.status != VisitStatus.pendingRegistration) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isCancelling && context.canPop()) context.pop();
      });
    }
    if (visit == null) return const Scaffold(body: LoadingView());

    final code = visit.accessCode;
    final link = code == null ? null : fastlaneLink(code);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(context.l10n.visitsPendingTitle),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(GatesSpacing.space24),
          children: [
            Text(
              context.l10n.visitsPendingIntro,
              style: GatesTypography.body.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: GatesSpacing.space24),
            _SummaryCard(
              arrival: _arrivalLabel(context.l10n, visit.validFrom),
              link: link,
            ),
            if (link != null) ...[
              const SizedBox(height: GatesSpacing.space24),
              GatesButton(
                label: context.l10n.visitsPendingShare,
                onPressed: () => _share(visit, link),
              ),
              const SizedBox(height: GatesSpacing.space8),
              GatesTextAction(
                label: context.l10n.visitsPendingCopyLink,
                onPressed: () => _copyLink(link),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(GatesSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GatesTextAction(
              label: context.l10n.visitsPendingEdit,
              filled: true,
              onPressed: () =>
                  context.push('/visits/${visit.id}/edit', extra: visit),
            ),
            const SizedBox(height: 20),
            if (widget.justCreated)
              GatesTextAction(
                label: context.l10n.visitsPendingGoToVisits,
                onPressed: () => context.go(
                  '/',
                  extra: const HomeTabRequest(HomeShell.visitsTab),
                ),
              )
            else
              GatesTextAction(
                label: context.l10n.visitsPendingCancel,
                color: context.palette.statusError,
                onPressed: _isCancelling ? null : () => _cancel(visit),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Invitación / Resumen y estado" — Figma node 402:1939.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.arrival, required this.link});

  final String arrival;
  final String? link;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        border: Border.all(color: context.palette.borderDefault),
        borderRadius: BorderRadius.circular(GatesRadius.radius16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.visitsPendingExpectedArrival,
            style: context.gatesText.caption.copyWith(fontSize: 13),
          ),
          const SizedBox(height: GatesSpacing.space4),
          Text(
            arrival,
            style: GatesTypography.body.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 26 / 18,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.palette.bgSubtle,
              borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
            ),
            child: Text(
              context.l10n.visitsPendingDataStatus,
              style: context.gatesText.caption.copyWith(
                color: context.palette.textBrand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.visitsPendingVisitorWillComplete,
            style: GatesTypography.body.copyWith(
              fontSize: 14,
              color: context.palette.textSecondary,
              height: 21 / 14,
            ),
          ),
          if (link != null) ...[
            const SizedBox(height: 20),
            Text(
              context.l10n.visitsPendingLinkLabel,
              style: context.gatesText.caption,
            ),
            const SizedBox(height: GatesSpacing.space4),
            Text(
              link!,
              style: GatesTypography.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.palette.textSecondary,
                height: 20 / 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
