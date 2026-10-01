import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_sheet.dart';
import '../../../core/widgets/swipe_to_confirm.dart';
import '../domain/amenity_booking.dart';
import 'amenities_controller.dart';
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
      return spec(p.tonePending, 'Pendiente de confirmación');
    case BookingStatus.confirmed:
      return booking.isUpcoming
          ? spec(p.toneConfirmed, 'Reserva confirmada')
          : spec(p.toneNeutral, 'Reserva pasada');
    case BookingStatus.cancelled:
      return spec(p.toneCancelled, 'Reserva cancelada');
    case BookingStatus.expired:
      return spec(p.toneNeutral, 'Reserva expirada');
  }
}

String _durationLabel(AmenityBooking booking) {
  final minutes = booking.endTime.difference(booking.startTime).inMinutes;
  final hours = minutes / 60;
  return hours == hours.roundToDouble()
      ? '${hours.round()} horas'
      : '$minutes minutos';
}

String _capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

/// "Bottom sheet / Detalle de reserva" — Figma "R04 · Detalle de reserva".
Future<void> showBookingDetailSheet(
  BuildContext context,
  WidgetRef ref,
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
  bool _cancelling = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmCancel() async {
    setState(() => _cancelling = true);
    try {
      await ref
          .read(amenitiesRepositoryProvider)
          .cancelBooking(widget.booking.id, reason: _reasonController.text);
      ref.invalidate(myBookingsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _cancelling = false);
        showGatesToast(
          context,
          type: GatesToastType.error,
          title: 'No pudimos cancelar la reserva',
          message: 'Intenta de nuevo.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
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
                    'Detalle de reserva',
                    style: _detailHeaderStyle(context),
                  ),
                ),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    tooltip: 'Cerrar',
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _cancelling
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: GatesSpacing.space16),
            _StatusPill(spec: pill),
            const SizedBox(height: GatesSpacing.space16),
            _DetailRow(label: 'Espacio', value: booking.amenityName),
            const SizedBox(height: GatesSpacing.space16),
            _DetailRow(
              label: 'Fecha',
              value: _capitalize(_fullDateFormat.format(booking.startTime)),
            ),
            const SizedBox(height: GatesSpacing.space16),
            _DetailRow(
              label: 'Horario',
              value:
                  '${_timeFormat.format(booking.startTime)}–${_timeFormat.format(booking.endTime)}'
                  ' · ${_durationLabel(booking)}',
            ),
            if (booking.status == BookingStatus.cancelled &&
                (booking.rejectionReason?.isNotEmpty ?? false)) ...[
              const SizedBox(height: GatesSpacing.space16),
              _DetailRow(label: 'Motivo', value: booking.rejectionReason!),
            ],
            if (booking.isCancellable) ...[
              const SizedBox(height: GatesSpacing.space16),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                enabled: !_cancelling,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                  hintText: 'Cuéntanos por qué cancelas, si quieres',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: GatesSpacing.space16),
              SwipeToConfirm(
                label: 'Desliza para cancelar',
                loading: _cancelling,
                onConfirmed: _handleConfirmCancel,
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
