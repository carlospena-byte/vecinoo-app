import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_sheet.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../../l10n/l10n.dart';
import '../domain/visit.dart';
import 'visit_cancel_service.dart';
import 'visit_failure_text.dart';

/// "Bottom sheet / Detalle de visita" — Figma node 118:286. Shows what the
/// resident authorized (status, who, unit, validity, notes) and lets them
/// cancel it while it hasn't happened yet.
Future<void> showVisitDetailSheet(
  BuildContext context, {
  required Visit visit,
  required String unitName,
}) {
  return showGatesSheet<void>(
    context,
    (_) => _VisitDetailSheet(visit: visit, unitName: unitName),
  );
}

String _dayLabel(AppLocalizations l10n, DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return l10n.visitsToday;
  if (day == today.add(const Duration(days: 1))) return l10n.visitsTomorrow;
  return _shortDate(date);
}

/// "23 sep." — plus the year when it isn't the current one.
String _shortDate(DateTime date) {
  final base = '${DateFormat('d MMM', 'es').format(date).replaceAll('.', '')}.';
  return date.year == DateTime.now().year ? base : '$base ${date.year}';
}

/// "23 sep. 2026" — always with the year, as in the banner.
String _fullDate(DateTime date) =>
    '${DateFormat('d MMM', 'es').format(date).replaceAll('.', '')}. ${date.year}';

String _time(DateTime date) => DateFormat('HH:mm', 'es').format(date);

String _kindLabel(AppLocalizations l10n, Visit v) => switch (v.visitType) {
  VisitType.delivery => providerKindLabel(
    l10n,
    v.providerKind ?? ProviderKind.delivery,
  ),
  VisitType.fastlane => l10n.visitsListSubtitleFastlane,
  VisitType.frequent => l10n.visitsTypeFrequent,
}.toUpperCase();

/// "Hoy, 00:00 a 23:59" for a same-day window, otherwise both ends spelled out.
String _validity(AppLocalizations l10n, Visit v) {
  final from = v.validFrom;
  final until = v.validUntil;
  final sameDay =
      from.year == until.year &&
      from.month == until.month &&
      from.day == until.day;
  return sameDay
      ? l10n.visitsDetailValiditySameDay(
          _dayLabel(l10n, from),
          _time(from),
          _time(until),
        )
      : l10n.visitsDetailValidityRange(
          '${_shortDate(from)} ${_time(from)}',
          '${_shortDate(until)} ${_time(until)}',
        );
}

bool _canCancel(Visit v) =>
    v.status == VisitStatus.pendingRegistration ||
    v.status == VisitStatus.scheduled ||
    v.status == VisitStatus.active;

class _VisitDetailSheet extends ConsumerStatefulWidget {
  const _VisitDetailSheet({required this.visit, required this.unitName});

  final Visit visit;
  final String unitName;

  @override
  ConsumerState<_VisitDetailSheet> createState() => _VisitDetailSheetState();
}

class _VisitDetailSheetState extends ConsumerState<_VisitDetailSheet> {
  bool _isCancelling = false;

  Future<void> _cancel() async {
    setState(() => _isCancelling = true);
    final failure = await ref
        .read(visitCancelServiceProvider)
        .cancelVisit(widget.visit.id);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
      showGatesToast(
        context,
        type: GatesToastType.success,
        title: context.l10n.visitsDetailCancelledToast,
      );
    } else {
      setState(() => _isCancelling = false);
      showGatesToast(
        context,
        type: GatesToastType.error,
        title: context.l10n.visitsDetailCancelError,
        message: withFailureDetail(
          context.l10n,
          failure,
          context.l10n.visitsTryAgain,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    final notes = visit.notes?.trim() ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        GatesSpacing.space24,
        0,
        GatesSpacing.space24,
        GatesSpacing.space24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GatesSheetHeader(title: context.l10n.visitsDetailTitle),
          const SizedBox(height: GatesSpacing.space12),
          _StatusBanner(
            status: visit.status,
            detail:
                '${_dayLabel(context.l10n, visit.validFrom)} · ${_fullDate(visit.validFrom)}',
          ),
          const SizedBox(height: GatesSpacing.space12),
          _Field(
            label: _kindLabel(context.l10n, visit),
            value: visit.name ?? context.l10n.visitsPendingInvitationName,
          ),
          _Field(label: context.l10n.visitsUnit, value: widget.unitName),
          _Field(
            label: context.l10n.visitsDetailValidity,
            value: _validity(context.l10n, visit),
          ),
          if (visit.plate != null && visit.plate!.isNotEmpty)
            _Field(label: context.l10n.visitsPlate, value: visit.plate!),
          if (notes.isNotEmpty)
            _Field(label: context.l10n.visitsGateNotes, value: notes),
          if (_canCancel(visit)) ...[
            const SizedBox(height: GatesSpacing.space4),
            SizedBox(
              width: double.infinity,
              child: GatesButton(
                label: context.l10n.visitsCancelVisit,
                style: GatesButtonStyle.destructive,
                loading: _isCancelling,
                onPressed: _isCancelling ? null : _cancel,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status, required this.detail});

  final VisitStatus status;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      VisitStatus.pendingRegistration => (
        context.palette.statusWarningBg,
        context.palette.statusWarning,
      ),
      VisitStatus.scheduled ||
      VisitStatus.active ||
      VisitStatus.inside ||
      VisitStatus.completed => (
        context.palette.statusSuccessBg,
        context.palette.statusSuccess,
      ),
      VisitStatus.cancelled || VisitStatus.rejected || VisitStatus.expired => (
        context.palette.bgSubtle,
        context.palette.textSecondary,
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GatesSpacing.space16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            visitStatusLabel(context.l10n, status),
            style: GatesTypography.label.copyWith(
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
          const SizedBox(height: GatesSpacing.space8),
          Text(detail, style: GatesTypography.caption),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GatesSpacing.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.gatesText.caption),
          const SizedBox(height: GatesSpacing.space4),
          Text(
            value,
            style: GatesTypography.label.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
