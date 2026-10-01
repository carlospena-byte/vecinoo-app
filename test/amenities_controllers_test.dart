import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/amenities/domain/amenities_repository.dart';
import 'package:gates_app/features/amenities/domain/amenity.dart';
import 'package:gates_app/features/amenities/domain/amenity_blackout.dart';
import 'package:gates_app/features/amenities/domain/amenity_booking.dart';
import 'package:gates_app/features/amenities/domain/amenity_details.dart';
import 'package:gates_app/features/amenities/presentation/amenities_controller.dart';
import 'package:gates_app/features/amenities/presentation/amenity_detail_controller.dart';
import 'package:gates_app/features/amenities/presentation/booking_date_time_controller.dart';
import 'package:gates_app/features/amenities/presentation/booking_selection.dart';
import 'package:gates_app/features/amenities/presentation/bookings_list_controller.dart';
import 'package:gates_app/features/amenities/presentation/cancel_booking_controller.dart';
import 'package:gates_app/features/amenities/presentation/review_booking_controller.dart';
import 'package:gates_app/features/session/domain/membership.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';

class _Membership extends SelectedMembershipController {
  @override
  Future<Membership?> build() async => const Membership(
    residentialId: 'res-1',
    residentialName: 'Los Olivos',
    unitId: 'unit-1',
    unitName: 'A-204',
  );
}

class _Created {
  _Created(
    this.amenityId,
    this.residentialId,
    this.unitId,
    this.start,
    this.end,
    this.notes,
  );
  final String amenityId;
  final String residentialId;
  final String unitId;
  final DateTime start;
  final DateTime end;
  final String? notes;
}

class _Repository implements AmenitiesRepository {
  final created = <_Created>[];
  final cancelled = <(String, String?)>[];
  Object? error;
  int bookingsFetches = 0;

  @override
  Future<AmenityBooking> createBooking({
    required String amenityId,
    required String residentialId,
    required String unitId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    if (error != null) throw error!;
    created.add(
      _Created(amenityId, residentialId, unitId, startTime, endTime, notes),
    );
    return _booking('b1', startTime, endTime);
  }

  @override
  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    if (error != null) throw error!;
    cancelled.add((bookingId, reason));
  }

  @override
  Future<List<AmenityBooking>> fetchMyBookings() async {
    bookingsFetches++;
    return const [];
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

AmenityBooking _booking(
  String id,
  DateTime start,
  DateTime end, {
  BookingStatus status = BookingStatus.pending,
}) => AmenityBooking(
  id: id,
  amenityId: 'a1',
  amenityName: 'Salón',
  startTime: start,
  endTime: end,
  status: status,
);

Amenity _amenity({int? duration}) => Amenity(
  id: 'a1',
  residentialId: 'res-1',
  name: 'Salón',
  requiresBooking: true,
  bookingDurationMinutes: duration,
);

final _now = DateTime(2030, 6, 10, 12);

AmenityDetails _details({
  int? duration = 60,
  List<AmenityBlackout> blackouts = const [],
}) => AmenityDetails(
  amenity: _amenity(duration: duration),
  images: const [],
  services: const [],
  bookingLimits: const [],
  blackouts: blackouts,
);

ProviderContainer _container(_Repository repository) {
  final container = ProviderContainer(
    overrides: [
      amenitiesRepositoryProvider.overrideWithValue(repository),
      amenitiesClockProvider.overrideWithValue(() => _now),
      selectedMembershipProvider.overrideWith(_Membership.new),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

BookingSelection _selection({
  DateTime? day,
  TimeOfDay start = const TimeOfDay(hour: 15, minute: 0),
  TimeOfDay end = const TimeOfDay(hour: 16, minute: 0),
}) =>
    BookingSelection(day: day ?? DateTime(2030, 6, 12), start: start, end: end);

void main() {
  group('ReviewBookingController', () {
    late _Repository repository;
    late ProviderContainer container;
    late ReviewBookingArgs args;

    ReviewBookingController start(BookingSelection selection) {
      args = ReviewBookingArgs(details: _details(), selection: selection);
      final provider = reviewBookingControllerProvider(args);
      container.listen(provider, (_, _) {});
      return container.read(provider.notifier);
    }

    ReviewBookingState state() =>
        container.read(reviewBookingControllerProvider(args));

    setUp(() {
      repository = _Repository();
      container = _container(repository);
      container.read(selectedMembershipProvider.future);
    });

    test(
      'creates the booking with the right payload and emits the result',
      () async {
        await container.read(selectedMembershipProvider.future);
        final controller = start(_selection());
        controller.setNotes('Cumpleaños');
        final events = <BookingCreated>[];
        controller.events.listen(events.add);

        await controller.confirm();
        await Future<void>.delayed(Duration.zero);

        expect(repository.created, hasLength(1));
        final created = repository.created.single;
        expect(created.amenityId, 'a1');
        expect(created.residentialId, 'res-1');
        expect(created.unitId, 'unit-1');
        expect(created.start, DateTime(2030, 6, 12, 15));
        expect(created.end, DateTime(2030, 6, 12, 16));
        expect(created.notes, 'Cumpleaños');
        expect(events.single.booking.id, 'b1');
        expect(state().isSubmitting, isFalse);
        expect(state().error, isNull);
      },
    );

    test('empty notes are sent as null', () async {
      await container.read(selectedMembershipProvider.future);
      final controller = start(_selection());
      controller.setNotes('x');
      controller.setNotes('');
      await controller.confirm();
      expect(repository.created.single.notes, isNull);
    });

    test(
      'rejects a start in the past without calling the repository',
      () async {
        await container.read(selectedMembershipProvider.future);
        final controller = start(_selection(day: DateTime(2030, 6, 9)));
        await controller.confirm();
        expect(state().error?.kind, ReviewBookingErrorKind.pastDate);
        expect(repository.created, isEmpty);
      },
    );

    test('rejects an end that is not after the start', () async {
      await container.read(selectedMembershipProvider.future);
      final controller = start(
        _selection(end: const TimeOfDay(hour: 15, minute: 0)),
      );
      await controller.confirm();
      expect(state().error?.kind, ReviewBookingErrorKind.endNotAfterStart);
      expect(repository.created, isEmpty);
    });

    test('changing the selection clears the error', () async {
      await container.read(selectedMembershipProvider.future);
      final controller = start(_selection(day: DateTime(2030, 6, 9)));
      await controller.confirm();
      expect(state().error, isNotNull);
      controller.changeSelection(_selection());
      expect(state().error, isNull);
      expect(state().selection, _selection());
    });

    test('slot conflict becomes a conflict error', () async {
      await container.read(selectedMembershipProvider.future);
      repository.error = const BookingConflictException();
      final controller = start(_selection());
      await controller.confirm();
      expect(state().error?.kind, ReviewBookingErrorKind.conflict);
      expect(state().isSubmitting, isFalse);
    });

    test('blackout rejection becomes a blackout error', () async {
      await container.read(selectedMembershipProvider.future);
      repository.error = const AmenityBlackoutException();
      final controller = start(_selection());
      await controller.confirm();
      expect(state().error?.kind, ReviewBookingErrorKind.blackout);
    });

    test('other errors become a typed submit failure', () async {
      await container.read(selectedMembershipProvider.future);
      repository.error = const NetworkFailure();
      final controller = start(_selection());
      await controller.confirm();
      expect(state().error?.kind, ReviewBookingErrorKind.submit);
      expect(state().error?.failure, isA<NetworkFailure>());
    });

    test('raw errors are mapped through Failure.from', () async {
      await container.read(selectedMembershipProvider.future);
      repository.error = StateError('boom');
      final controller = start(_selection());
      await controller.confirm();
      expect(state().error?.failure, isA<UnknownFailure>());
    });

    test('a successful booking refreshes the bookings list', () async {
      await container.read(selectedMembershipProvider.future);
      container.listen(myBookingsProvider, (_, _) {});
      await container.read(myBookingsProvider.future);
      final controller = start(_selection());
      await controller.confirm();
      await container.read(myBookingsProvider.future);
      expect(repository.bookingsFetches, 2);
    });
  });

  group('BookingDateTimeController', () {
    BookingDateTimeController make(
      ProviderContainer container,
      BookingDateTimeArgs args,
    ) {
      final provider = bookingDateTimeControllerProvider(args);
      container.listen(provider, (_, _) {});
      return container.read(provider.notifier);
    }

    test('blacked-out and past days are disabled', () {
      final container = _container(_Repository());
      final controller = make(
        container,
        BookingDateTimeArgs(
          amenity: _amenity(duration: 60),
          blackouts: [
            AmenityBlackout(
              id: 'x',
              amenityId: 'a1',
              startDate: DateTime(2030, 6, 20),
              endDate: DateTime(2030, 6, 22),
            ),
          ],
        ),
      );
      expect(controller.isDayEnabled(DateTime(2030, 6, 19)), isTrue);
      expect(controller.isDayEnabled(DateTime(2030, 6, 21)), isFalse);
      expect(controller.isDayEnabled(DateTime(2030, 6, 1)), isFalse);
    });

    test('fixed duration computes the end from the start', () {
      final container = _container(_Repository());
      final controller = make(
        container,
        BookingDateTimeArgs(
          amenity: _amenity(duration: 90),
          blackouts: const [],
        ),
      );
      controller.setStart(const TimeOfDay(hour: 23, minute: 30));
      expect(controller.computedEnd, const TimeOfDay(hour: 1, minute: 0));
    });

    test('fixed duration confirms with the computed end', () async {
      final container = _container(_Repository());
      final controller = make(
        container,
        BookingDateTimeArgs(
          amenity: _amenity(duration: 60),
          blackouts: const [],
        ),
      );
      final events = <BookingSelectionConfirmed>[];
      controller.events.listen(events.add);
      controller.setStart(const TimeOfDay(hour: 10, minute: 15));
      controller.submit();
      await Future<void>.delayed(Duration.zero);
      expect(
        events.single.selection.start,
        const TimeOfDay(hour: 10, minute: 15),
      );
      expect(
        events.single.selection.end,
        const TimeOfDay(hour: 11, minute: 15),
      );
      expect(events.single.selection.day, _now);
    });

    test('flexible duration rejects an end before the start', () async {
      final container = _container(_Repository());
      final args = BookingDateTimeArgs(
        amenity: _amenity(),
        blackouts: const [],
      );
      final controller = make(container, args);
      final events = <BookingSelectionConfirmed>[];
      controller.events.listen(events.add);
      controller.setStart(const TimeOfDay(hour: 12, minute: 0));
      controller.setEnd(const TimeOfDay(hour: 11, minute: 0));
      controller.submit();
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
      expect(
        container.read(bookingDateTimeControllerProvider(args)).error,
        BookingDateTimeError.endBeforeStart,
      );
      controller.setEnd(const TimeOfDay(hour: 13, minute: 0));
      expect(
        container.read(bookingDateTimeControllerProvider(args)).error,
        isNull,
      );
    });
  });

  group('CancelBookingController', () {
    test('cancels with the reason, refreshes and emits', () async {
      final repository = _Repository();
      final container = _container(repository);
      final provider = cancelBookingControllerProvider('b1');
      container.listen(provider, (_, _) {});
      final events = <CancelBookingEvent>[];
      container.read(provider.notifier).events.listen(events.add);

      await container.read(provider.notifier).cancel(reason: 'No puedo');
      await Future<void>.delayed(Duration.zero);

      expect(repository.cancelled.single, ('b1', 'No puedo'));
      expect(events.single, isA<BookingCancelled>());
    });

    test('failures become typed events and re-enable the sheet', () async {
      final repository = _Repository()..error = const ServerFailure();
      final container = _container(repository);
      final provider = cancelBookingControllerProvider('b1');
      container.listen(provider, (_, _) {});
      final events = <CancelBookingEvent>[];
      container.read(provider.notifier).events.listen(events.add);

      await container.read(provider.notifier).cancel();
      await Future<void>.delayed(Duration.zero);

      final event = events.single as CancelBookingFailed;
      expect(event.failure, isA<ServerFailure>());
      expect(container.read(provider).isCancelling, isFalse);
    });
  });

  group('AmenityDetailController', () {
    test('forwards the picked selection as review args', () async {
      final container = _container(_Repository());
      final provider = amenityDetailControllerProvider('a1');
      container.listen(provider, (_, _) {});
      final controller = container.read(provider.notifier);
      final events = <ReviewRequested>[];
      controller.events.listen(events.add);
      final details = _details();
      controller.continueToReview(details, _selection());
      controller.setGalleryPage(2);
      await Future<void>.delayed(Duration.zero);
      expect(events.single.args.details, same(details));
      expect(events.single.args.selection, _selection());
      expect(container.read(provider).galleryPage, 2);
    });
  });

  group('bookingsForTab', () {
    test('splits upcoming pending/confirmed from history', () {
      final future = DateTime.now().add(const Duration(days: 2));
      final later = DateTime.now().add(const Duration(days: 3));
      final past = DateTime.now().subtract(const Duration(days: 3));
      final h = const Duration(hours: 1);
      final bookings = [
        _booking('p2', later, later.add(h)),
        _booking('p1', future, future.add(h)),
        _booking('c1', future, future.add(h), status: BookingStatus.confirmed),
        _booking('x1', future, future.add(h), status: BookingStatus.cancelled),
        _booking('old', past, past.add(h), status: BookingStatus.confirmed),
      ];
      expect(bookingsForTab(bookings, BookingsTab.pending).map((b) => b.id), [
        'p1',
        'p2',
      ]);
      expect(bookingsForTab(bookings, BookingsTab.confirmed).map((b) => b.id), [
        'c1',
      ]);
      expect(
        bookingsForTab(bookings, BookingsTab.history).map((b) => b.id).toSet(),
        {'x1', 'old'},
      );
    });
  });
}
