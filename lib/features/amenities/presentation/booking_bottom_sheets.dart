import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/error/failure_messages.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_sheet.dart';
import '../../../core/widgets/swipe_to_confirm.dart';
import '../domain/amenity_booking.dart';
import '../../../l10n/l10n.dart';
import 'cancel_booking_controller.dart';
import 'amenity_formatters.dart';
import '../../../core/widgets/gates_toast.dart';

final _fullDateFormat = DateFormat('EEEE d \'de\' MMMM \'de\' y', 'es');
final _timeFormat = DateFormat('HH:mm', 'es');

TextStyle _detailHeaderStyle(BuildContext context) => TextStyle(
  fontFamily: 'Manrope',
  fontWeight: FontWeight.w700,
  fontSize: 22,
  height: 30 / 22,
  color: context.palette.textPrimary,
);

TextStyle _detailLabelStyle(BuildContext context) => TextStyle(
  fontFamily: 'Manrope',
  fontWeight: FontWeight.w500,
  fontSize: 12,
  height: 16 / 12,
  color: context.palette.textSecondary,
);

TextStyle _detailValueStyle(BuildContext context) => TextStyle(
  fontFamily: 'Manrope',
  fontWeight: FontWeight.w600,
  fontSize: 15,
  height: 22 / 15,
  color: context.palette.textPrimary,
);

class _StatusPillSpec {
  const _StatusPillSpec({
    required this.background,
    required this.border,
    required this.foreground,
    required this.label,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final String label;
}

/// "Status pill / …" — Figma nodes 317:215 (Pendiente), 319:1490 (Confirmada),
/// 321:1490 (Cancelada) and 321:1508 (Pasada).
_StatusPillSpec _statusPillSpec(BuildContext context, AmenityBooking booking) {
  final p = context.palette;
  _StatusPillSpec spec(GatesTone tone, String label) => _StatusPillSpec(
    background: tone.background,
    border: tone.border,
    foreground: tone.foreground,
    label: label,
  );
  switch (booking.status) {
    case BookingStatus.pending:
      return spec(p.tonePending, context.l10n.amenitiesPendingConfirmation);
    case BookingStatus.confirmed:
      return booking.isUpcoming
          ? spec(p.toneConfirmed, context.l10n.amenitiesPillConfirmed)
          : spec(p.toneNeutral, context.l10n.amenitiesPillPast);
    case BookingStatus.cancelled:
      return spec(p.toneCancelled, context.l10n.amenitiesPillCancelled);
    case BookingStatus.expired:
      return spec(p.toneNeutral, context.l10n.amenitiesPillExpired);
  }
}

String _capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

/// "Bottom sheet / Detalle de reserva" — Figma "R04 · Detalle de reserva".
Future<void> showBookingDetailSheet(
  BuildContext context,
  AmenityBooking booking,
) {
  return showGatesSheet(
    context,
    (context) => _BookingDetailSheetBody(booking: booking),
  );
}

/// Everything inside the sheet, including the inline cancel flow — a
/// StatefulWidget (rather than the plain builder this used to be) so the
/// reason field and the swipe-to-confirm track can live in the same sheet
/// instead of stacking a confirm AlertDialog on top of it.
class _BookingDetailSheetBody extends ConsumerStatefulWidget {
  const _BookingDetailSheetBody({required this.booking});

  final AmenityBooking booking;

  @override
  ConsumerState<_BookingDetailSheetBody> createState() =>
      _BookingDetailSheetBodyState();
}

class _BookingDetailSheetBodyState
    extends ConsumerState<_BookingDetailSheetBody> {
  final _reasonController = TextEditingController();
  StreamSubscription<CancelBookingEvent>? _events;

  CancelBookingController get _controller =>
      ref.read(cancelBookingControllerProvider(widget.booking.id).notifier);

  @override
  void initState() {
    super.initState();
    _events = _controller.events.listen(_onEvent);
  }

  @override
  void dispose() {
    _events?.cancel();
    _reasonController.dispose();
    super.dispose();
  }

  void _onEvent(CancelBookingEvent event) {
    if (!mounted) return;
    switch (event) {
      case BookingCancelled():
        Navigator.of(context).pop();
      case CancelBookingFailed(:final failure):
        final l10n = context.l10n;
        final detail = failureDetail(l10n, failure);
        showGatesToast(
          context,
          type: GatesToastType.error,
          title: l10n.amenitiesCancelFailedTitle,
          message: detail == null
              ? l10n.amenitiesTryAgain
              : '$detail ${l10n.amenitiesTryAgain}',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final cancelling = ref
        .watch(cancelBookingControllerProvider(booking.id))
        .isCancelling;
    final pill = _statusPillSpec(context, booking);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GatesSpacing.space24,
          0,
          GatesSpacing.space24,
          GatesSpacing.space24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.amenitiesBookingDetailTitle,
                    style: _detailHeaderStyle(context),
                  ),
                ),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    tooltip: context.l10n.amenitiesClose,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: cancelling
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: GatesSpacing.space16),
            _StatusPill(spec: pill),
            const SizedBox(height: GatesSpacing.space16),
            _DetailRow(
              label: context.l10n.amenitiesSpace,
              value: booking.amenityName,
            ),
            const SizedBox(height: GatesSpacing.space16),
            _DetailRow(
              label: context.l10n.amenitiesDate,
              value: _capitalize(_fullDateFormat.format(booking.startTime)),
            ),
            const SizedBox(height: GatesSpacing.space16),
            _DetailRow(
              label: context.l10n.amenitiesSchedule,
              value:
                  '${_timeFormat.format(booking.startTime)}–${_timeFormat.format(booking.endTime)}'
                  ' · ${amenityDurationLabel(context.l10n, booking.endTime.difference(booking.startTime).inMinutes)}',
            ),
            if (booking.status == BookingStatus.cancelled &&
                (booking.rejectionReason?.isNotEmpty ?? false)) ...[
              const SizedBox(height: GatesSpacing.space16),
              _DetailRow(
                label: context.l10n.amenitiesReason,
                value: booking.rejectionReason!,
              ),
            ],
            if (booking.isCancellable) ...[
              const SizedBox(height: GatesSpacing.space16),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                enabled: !cancelling,
                decoration: InputDecoration(
                  labelText: context.l10n.amenitiesReasonOptional,
                  hintText: context.l10n.amenitiesReasonHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: GatesSpacing.space16),
              SwipeToConfirm(
                label: context.l10n.amenitiesSwipeToCancel,
                loading: cancelling,
                onConfirmed: () =>
                    _controller.cancel(reason: _reasonController.text),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.spec});

  final _StatusPillSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: spec.background,
        border: Border.all(color: spec.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: spec.foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: GatesSpacing.space8),
          Text(
            spec.label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 18 / 13,
              color: spec.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Detail row / …" — Figma nodes 319:1493/1496/1499 (label + value stack).
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _detailLabelStyle(context)),
        const SizedBox(height: GatesSpacing.space4),
        Text(value, style: _detailValueStyle(context)),
      ],
    );
  }
}
