import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../session/presentation/session_controller.dart';
import '../data/amenities_repository.dart';
import '../domain/amenity.dart';
import '../domain/amenity_details.dart';
import 'amenities_controller.dart';
import 'amenity_bottom_sheets.dart';
import 'booking_date_time_sheet.dart';
import 'booking_result_screen.dart';

/// Arguments for `/amenities/:id/review` — the amenity's full details (for
/// the blackouts list and cost/terms sheets) plus the day/time the resident
/// just picked in [BookingDateTimeSheet].
class ReviewBookingArgs {
  const ReviewBookingArgs({required this.details, required this.selection});

  final AmenityDetails details;
  final BookingSelection selection;
}

final _dateFormat = DateFormat('EEE, d MMM y', 'es');
final _timeFormat = DateFormat('HH:mm');

String _durationLabel(int minutes) {
  if (minutes % 60 == 0) {
    final hours = minutes ~/ 60;
    return hours == 1 ? '1 hora' : '$hours horas';
  }
  return '$minutes minutos';
}

/// "Revisar reserva" — Figma "B02" (node 265:1422). Lets the resident change
/// the date/time, notes, or check cost/terms before confirming; on submit it
/// shows an inline recoverable-error banner rather than a separate screen,
/// matching "B07–B10" in the Figma flow.
class ReviewBookingScreen extends ConsumerStatefulWidget {
  const ReviewBookingScreen({super.key, required this.args});

  final ReviewBookingArgs args;

  @override
  ConsumerState<ReviewBookingScreen> createState() =>
      _ReviewBookingScreenState();
}

class _ReviewBookingScreenState extends ConsumerState<ReviewBookingScreen> {
  late BookingSelection _selection;
  String? _notes;
  bool _isSubmitting = false;
  ({String title, String message})? _error;

  Amenity get _amenity => widget.args.details.amenity;

  @override
  void initState() {
    super.initState();
    _selection = widget.args.selection;
  }

  Future<void> _changeDateTime() async {
    final result = await showBookingDateTimeSheet(
      context,
      amenity: _amenity,
      blackouts: widget.args.details.blackouts,
      initial: _selection,
      primaryLabel: 'Guardar',
    );
    if (result != null && mounted) {
      setState(() {
        _selection = result;
        _error = null;
      });
    }
  }

  Future<void> _editNotes() async {
    final result = await showEditNotesSheet(context, initialNotes: _notes);
    if (result != null && mounted) {
      setState(() => _notes = result.isEmpty ? null : result);
    }
  }

  Future<void> _confirm() async {
    final now = DateTime.now();
    if (_selection.startDateTime.isBefore(now)) {
      setState(
        () => _error = (
          title: 'Fecha en el pasado',
          message:
              'La fecha seleccionada ya pasó. Elige una fecha actual o futura.',
        ),
      );
      return;
    }
    if (!_selection.endDateTime.isAfter(_selection.startDateTime)) {
      setState(
        () => _error = (
          title: 'Error de horario',
          message: 'La hora de fin debe ser después de la hora de inicio.',
        ),
      );
      return;
    }

    final membership = ref.read(selectedMembershipProvider).value;
    if (membership == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final booking = await ref
          .read(amenitiesRepositoryProvider)
          .createBooking(
            amenityId: _amenity.id,
            residentialId: membership.residentialId,
            unitId: membership.unitId,
            startTime: _selection.startDateTime,
            endTime: _selection.endDateTime,
            notes: _notes,
          );
      ref.invalidate(myBookingsProvider);
      if (!mounted) return;
      context.pushReplacement(
        '/amenities/${_amenity.id}/result',
        extra: BookingResultArgs(amenity: _amenity, booking: booking),
      );
    } on BookingConflictException {
      setState(
        () => _error = (
          title: 'Horario no disponible',
          message: 'Otra reserva ocupa este horario. Tus notas se conservaron.',
        ),
      );
    } on AmenityBlackoutException {
      setState(
        () => _error = (
          title: 'Fecha cerrada',
          message: 'La amenidad estará cerrada el día elegido. Selecciona otra fecha.',
        ),
      );
    } catch (_) {
      setState(
        () => _error = (
          title: 'No se pudo enviar la reserva',
          message: 'Intenta de nuevo en unos segundos.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Revisar reserva'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(GatesSpacing.space24),
                children: [
                  if (_error != null) ...[
                    _ErrorBanner(
                      title: _error!.title,
                      message: _error!.message,
                    ),
                    const SizedBox(height: GatesSpacing.space16),
                  ],
                  Row(
                    children: [
                      _AmenityThumbnail(amenityId: _amenity.id),
                      const SizedBox(width: GatesSpacing.space16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _amenity.name,
                              style: GatesTypography.headingSmall,
                            ),
                            if (_amenity.location != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _amenity.location!,
                                style: context.gatesText.caption,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const _Divider(),
                  _ReviewRow(
                    label: 'Fecha',
                    value: _capitalize(_dateFormat.format(_selection.day)),
                    actionLabel: 'Cambiar',
                    onTap: _changeDateTime,
                  ),
                  const _Divider(),
                  _ReviewRow(
                    label: 'Horario',
                    value:
                        '${_timeFormat.format(_selection.startDateTime)}–'
                        '${_timeFormat.format(_selection.endDateTime)} · '
                        '${_durationLabel(_selection.endDateTime.difference(_selection.startDateTime).inMinutes)}',
                    actionLabel: 'Cambiar',
                    onTap: _changeDateTime,
                  ),
                  const _Divider(),
                  _ReviewRow(
                    label: 'Costo de la reserva',
                    value: _amenity.requiresPayment && _amenity.price != null
                        ? '\$${_amenity.price!.toStringAsFixed(2)}'
                        : 'Sin costo',
                  ),
                  const _Divider(),
                  _ReviewRow(
                    label: 'Notas (opcional)',
                    value: _notes ?? 'Sin notas',
                    actionLabel: 'Editar',
                    onTap: _editNotes,
                  ),
                  const _Divider(),
                  Text(
                    'Puedes cancelar una reserva futura desde Mis reservas.',
                    style: context.gatesText.caption,
                  ),
                  if (_amenity.terms != null) ...[
                    const SizedBox(height: GatesSpacing.space16),
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            showTermsSheet(context, _amenity.terms!),
                        child: const Text('Términos y condiciones'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GatesSpacing.space24,
                GatesSpacing.space12,
                GatesSpacing.space24,
                GatesSpacing.space24,
              ),
              child: SizedBox(
                width: double.infinity,
                child: GatesButton(
                  label: 'Confirmar reserva',
                  loading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _confirm,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    this.actionLabel,
    this.onTap,
  });

  final String label;
  final String value;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GatesTypography.label),
              const SizedBox(height: 4),
              Text(value, style: GatesTypography.body),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onTap, child: Text(actionLabel!)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: GatesSpacing.space16),
      child: Divider(height: 1, color: context.palette.borderSubtle),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GatesSpacing.space16),
      decoration: BoxDecoration(
        color: context.palette.statusErrorBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GatesTypography.label.copyWith(
              color: context.palette.statusError,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: context.gatesText.caption.copyWith(
              color: context.palette.statusError,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenityThumbnail extends ConsumerWidget {
  const _AmenityThumbnail({required this.amenityId});

  final String amenityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlsAsync = ref.watch(amenityImageUrlsProvider(amenityId));
    final url = urlsAsync.value?.values.firstOrNull;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 80,
        height: 80,
        child: url != null
            ? Image.network(url, fit: BoxFit.cover, excludeFromSemantics: true)
            : Container(
                color: context.palette.bgSubtle,
                alignment: Alignment.center,
                child: Icon(
                  Icons.deck_outlined,
                  color: context.palette.textSecondary,
                ),
              ),
      ),
    );
  }
}
