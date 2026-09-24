import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/state_views.dart';
import '../domain/amenity_booking.dart';
import 'amenities_controller.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis reservas')),
      body: bookingsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'No se pudieron cargar tus reservas.',
          onRetry: () => ref.invalidate(myBookingsProvider),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const EmptyView(
              message: 'Aún no tienes reservas.',
              icon: Icons.event_busy_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myBookingsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return _BookingCard(booking: booking);
              },
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.booking});

  final AmenityBooking booking;

  static final _dateFormat = DateFormat('EEE d MMM, h:mm a', 'es');

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: Text('¿Cancelar la reserva de ${booking.amenityName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(amenitiesRepositoryProvider).cancelBooking(booking.id);
    ref.invalidate(myBookingsProvider);
  }

  Color _statusColor(BuildContext context, BookingStatus status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case BookingStatus.confirmed:
        return scheme.primary;
      case BookingStatus.pending:
        return scheme.tertiary;
      case BookingStatus.cancelled:
        return scheme.outline;
    }
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Confirmada';
      case BookingStatus.pending:
        return 'Pendiente';
      case BookingStatus.cancelled:
        return 'Cancelada';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(booking.amenityName),
        subtitle: Text(
          '${_dateFormat.format(booking.startTime)} — ${DateFormat('h:mm a', 'es').format(booking.endTime)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(_statusLabel(booking.status)),
              backgroundColor: _statusColor(context, booking.status).withValues(alpha: 0.15),
              labelStyle: TextStyle(color: _statusColor(context, booking.status)),
            ),
            if (booking.isUpcoming)
              IconButton(
                tooltip: 'Cancelar',
                icon: const Icon(Icons.close),
                onPressed: () => _cancel(context, ref),
              ),
          ],
        ),
      ),
    );
  }
}
