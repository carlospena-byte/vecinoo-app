import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/error/failure_messages.dart';
import '../../../l10n/l10n.dart';
import '../domain/amenity.dart';
import 'amenity_bottom_sheets.dart';
import 'amenity_formatters.dart';
import 'booking_date_time_sheet.dart';
import 'booking_result_screen.dart';
import 'review_booking_controller.dart';
import 'review_booking_widgets.dart';

export 'review_booking_controller.dart' show ReviewBookingArgs;

final _dateFormat = DateFormat('EEE, d MMM y', 'es');
final _timeFormat = DateFormat('HH:mm');

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
  StreamSubscription<BookingCreated>? _events;

  Amenity get _amenity => widget.args.details.amenity;

  ReviewBookingController get _controller =>
      ref.read(reviewBookingControllerProvider(widget.args).notifier);

  @override
  void initState() {
    super.initState();
    _events = _controller.events.listen((event) {
      if (!mounted) return;
      context.pushReplacement(
        '/amenities/${_amenity.id}/result',
        extra: BookingResultArgs(amenity: _amenity, booking: event.booking),
      );
    });
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  Future<void> _changeDateTime(BookingSelection current) async {
    final result = await showBookingDateTimeSheet(
      context,
      amenity: _amenity,
      blackouts: widget.args.details.blackouts,
      initial: current,
      primaryLabel: context.l10n.amenitiesSave,
    );
    if (result != null && mounted) _controller.changeSelection(result);
  }

  Future<void> _editNotes(String? current) async {
    final result = await showEditNotesSheet(context, initialNotes: current);
    if (result != null && mounted) _controller.setNotes(result);
  }

  ({String title, String message}) _errorCopy(ReviewBookingError error) {
    final l10n = context.l10n;
    return switch (error.kind) {
      ReviewBookingErrorKind.pastDate => (
        title: l10n.amenitiesErrorPastDateTitle,
        message: l10n.amenitiesErrorPastDateMessage,
      ),
      ReviewBookingErrorKind.endNotAfterStart => (
        title: l10n.amenitiesErrorScheduleTitle,
        message: l10n.amenitiesEndAfterStartError,
      ),
      ReviewBookingErrorKind.conflict => (
        title: l10n.amenitiesErrorConflictTitle,
        message: l10n.amenitiesErrorConflictMessage,
      ),
      ReviewBookingErrorKind.blackout => (
        title: l10n.amenitiesErrorBlackoutTitle,
        message: l10n.amenitiesErrorBlackoutMessage,
      ),
      ReviewBookingErrorKind.submit => (
        title: l10n.amenitiesErrorSubmitTitle,
        message: _withDetail(
          error.failure == null ? null : failureDetail(l10n, error.failure!),
          l10n.amenitiesErrorSubmitMessage,
        ),
      ),
    };
  }

  String _withDetail(String? detail, String fallback) =>
      detail == null ? fallback : '$detail $fallback';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewBookingControllerProvider(widget.args));
    final selection = state.selection;
    final error = state.error;
    final notes = state.notes;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(context.l10n.amenitiesReviewTitle),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(GatesSpacing.space24),
                children: [
                  if (error != null) ...[
                    ReviewErrorBanner(
                      title: _errorCopy(error).title,
                      message: _errorCopy(error).message,
                    ),
                    const SizedBox(height: GatesSpacing.space16),
                  ],
                  Row(
                    children: [
                      ReviewAmenityThumbnail(amenityId: _amenity.id),
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
                  const ReviewDivider(),
                  ReviewRow(
                    label: context.l10n.amenitiesDate,
                    value: _capitalize(_dateFormat.format(selection.day)),
                    actionLabel: context.l10n.amenitiesChange,
                    onTap: () => _changeDateTime(selection),
                  ),
                  const ReviewDivider(),
                  ReviewRow(
                    label: context.l10n.amenitiesSchedule,
                    value:
                        '${_timeFormat.format(selection.startDateTime)}–'
                        '${_timeFormat.format(selection.endDateTime)} · '
                        '${amenityDurationLabel(context.l10n, selection.endDateTime.difference(selection.startDateTime).inMinutes)}',
                    actionLabel: context.l10n.amenitiesChange,
                    onTap: () => _changeDateTime(selection),
                  ),
                  const ReviewDivider(),
                  ReviewRow(
                    label: context.l10n.amenitiesCostHeading,
                    value: _amenity.requiresPayment && _amenity.price != null
                        ? '\$${_amenity.price!.toStringAsFixed(2)}'
                        : context.l10n.amenitiesNoCost,
                  ),
                  const ReviewDivider(),
                  ReviewRow(
                    label: context.l10n.amenitiesNotesOptional,
                    value: notes ?? context.l10n.amenitiesNoNotes,
                    actionLabel: context.l10n.amenitiesEdit,
                    onTap: () => _editNotes(notes),
                  ),
                  const ReviewDivider(),
                  Text(
                    context.l10n.amenitiesCancelFutureHint,
                    style: context.gatesText.caption,
                  ),
                  if (_amenity.terms != null) ...[
                    const SizedBox(height: GatesSpacing.space16),
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            showTermsSheet(context, _amenity.terms!),
                        child: Text(context.l10n.amenitiesTerms),
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
                  label: context.l10n.amenitiesConfirmBooking,
                  loading: state.isSubmitting,
                  onPressed: state.isSubmitting ? null : _controller.confirm,
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
