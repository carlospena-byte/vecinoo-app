import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/amenity_details.dart';
import 'booking_selection.dart';
import 'review_booking_controller.dart';

class AmenityDetailState {
  const AmenityDetailState({this.galleryPage = 0});

  /// Zero-based page the gallery is showing.
  final int galleryPage;
}

/// The resident picked a day/time: the screen opens the review step.
class ReviewRequested {
  const ReviewRequested(this.args);
  final ReviewBookingArgs args;
}

/// Gallery position and the hand-off from the date/time picker to the
/// review step for one amenity's detail screen.
class AmenityDetailController extends Notifier<AmenityDetailState> {
  AmenityDetailController(this.amenityId);

  final String amenityId;

  final _events = StreamController<ReviewRequested>.broadcast();

  Stream<ReviewRequested> get events => _events.stream;

  @override
  AmenityDetailState build() {
    ref.onDispose(_events.close);
    return const AmenityDetailState();
  }

  void setGalleryPage(int page) {
    if (page == state.galleryPage) return;
    state = AmenityDetailState(galleryPage: page);
  }

  void continueToReview(AmenityDetails details, BookingSelection selection) {
    _events.add(
      ReviewRequested(
        ReviewBookingArgs(details: details, selection: selection),
      ),
    );
  }
}

final amenityDetailControllerProvider = NotifierProvider.autoDispose
    .family<AmenityDetailController, AmenityDetailState, String>(
      AmenityDetailController.new,
    );
