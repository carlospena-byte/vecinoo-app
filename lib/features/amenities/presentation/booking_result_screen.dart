import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../home/home_shell.dart';
import '../domain/amenity.dart';
import '../domain/amenity_booking.dart';
import 'amenities_controller.dart';

/// Arguments for `/amenities/:id/result`.
class BookingResultArgs {
  const BookingResultArgs({required this.amenity, required this.booking});

  final Amenity amenity;
  final AmenityBooking booking;
}

final _summaryFormat = DateFormat("EEEE d 'de' MMMM", 'es');
final _timeFormat = DateFormat('HH:mm');

/// Shown right after a booking is created — Figma "B04 · Reserva confirmada"
/// / "B05 · Solicitud pendiente" (node 265:1905 / 265:1967). Which one
/// renders depends entirely on the `status` Postgres actually returned for
/// the new row (bookings default to `pending`; nothing here assumes
/// `confirmed` just because the insert succeeded).
class BookingResultScreen extends ConsumerStatefulWidget {
  const BookingResultScreen({super.key, required this.args});

  final BookingResultArgs args;

  @override
  ConsumerState<BookingResultScreen> createState() =>
      _BookingResultScreenState();
}

class _BookingResultScreenState extends ConsumerState<BookingResultScreen> {
  bool _bannerVisible = true;

  bool get _isConfirmed =>
      widget.args.booking.status == BookingStatus.confirmed;

  @override
  Widget build(BuildContext context) {
    final amenity = widget.args.amenity;
    final booking = widget.args.booking;

    final heading = _isConfirmed
        ? 'Todo listo para tu reserva'
        : 'Pendiente de confirmación';
    final subtext = _isConfirmed
        ? 'Consulta los datos y el estado desde Mis reservas.'
        : 'Tu solicitud fue enviada. Aún no está confirmada; consulta su estado en Mis reservas.';
    final appBarTitle = _isConfirmed
        ? 'Reserva confirmada'
        : 'Solicitud enviada';

    final urlsAsync = ref.watch(amenityImageUrlsProvider(amenity.id));
    final thumbnailUrl = urlsAsync.value?.values.firstOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(appBarTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              top: false,
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.all(GatesSpacing.space24),
                children: [
                  if (_bannerVisible) ...[
                    _StatusBanner(
                      confirmed: _isConfirmed,
                      onDismiss: () => setState(() => _bannerVisible = false),
                    ),
                    const SizedBox(height: GatesSpacing.space24),
                  ],
                  Text(heading, style: GatesTypography.headingMedium),
                  const SizedBox(height: GatesSpacing.space8),
                  Text(subtext, style: GatesTypography.body),
                  const SizedBox(height: GatesSpacing.space24),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          GatesRadius.radius8,
                        ),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: thumbnailUrl != null
                              ? Image.network(thumbnailUrl, fit: BoxFit.cover)
                              : Container(
                                  color: context.palette.bgSubtle,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.deck_outlined,
                                    color: context.palette.textSecondary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: GatesSpacing.space16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              amenity.name,
                              style: GatesTypography.headingSmall,
                            ),
                            if (amenity.location != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                amenity.location!,
                                style: context.gatesText.caption,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: GatesSpacing.space16,
                    ),
                    child: Divider(
                      height: 1,
                      color: context.palette.borderSubtle,
                    ),
                  ),
                  Text(
                    _capitalize(_summaryFormat.format(booking.startTime)),
                    style: GatesTypography.body,
                  ),
                  Text(
                    '${_timeFormat.format(booking.startTime)}–${_timeFormat.format(booking.endTime)} · '
                    '${_durationLabel(booking.endTime.difference(booking.startTime).inMinutes)}',
                    style: GatesTypography.body,
                  ),
                  if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                    const SizedBox(height: GatesSpacing.space16),
                    Text(
                      'Notas: ${booking.notes}',
                      style: context.gatesText.caption,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              GatesSpacing.space24,
              GatesSpacing.space12,
              GatesSpacing.space24,
              math.max(
                GatesSpacing.space24,
                MediaQuery.paddingOf(context).bottom,
              ),
            ),
            decoration: BoxDecoration(
              color: context.palette.bgSurface,
              border: Border(
                top: BorderSide(color: context.palette.borderSubtle),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: GatesButton(
                label: 'Ver mis reservas',
                onPressed: () => context.go(
                  '/',
                  extra: const HomeTabRequest(HomeShell.bookingsTab),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  String _durationLabel(int minutes) {
    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return hours == 1 ? '1 hora' : '$hours horas';
    }
    return '$minutes minutos';
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.confirmed, required this.onDismiss});

  final bool confirmed;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(GatesSpacing.space16),
      decoration: BoxDecoration(
        color: confirmed
            ? context.palette.statusSuccessBg
            : context.palette.bgLilac,
        borderRadius: BorderRadius.circular(GatesRadius.radius16),
      ),
      child: Row(
        children: [
          Icon(
            confirmed ? Icons.check_circle_outline : Icons.info_outline,
            size: 20,
            color: context.palette.textBrand,
          ),
          const SizedBox(width: GatesSpacing.space12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  confirmed ? 'Confirmada' : 'Pendiente',
                  style: GatesTypography.label,
                ),
                Text(
                  confirmed
                      ? 'La reserva se registró correctamente.'
                      : 'La solicitud espera confirmación.',
                  style: context.gatesText.caption,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onDismiss,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: EdgeInsets.all(GatesSpacing.space4),
              child: Icon(
                Icons.close,
                size: 20,
                color: context.palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
