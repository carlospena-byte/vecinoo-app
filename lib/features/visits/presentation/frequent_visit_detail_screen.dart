import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_sheet.dart';
import '../../../core/widgets/gates_text_action.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../../core/widgets/state_views.dart';
import '../../session/presentation/session_controller.dart';
import '../data/visits_repository.dart';
import '../domain/visit.dart';
import 'frequent_visit_formatters.dart';
import 'visits_controller.dart';

/// Detalle frecuente — Figma R04 (node 119:1141). Shows a frequent visit's
/// standing access (status banner, who, when, unit, last gate movement) and
/// lets the resident cancel it. Reads the row from the live
/// [visitsListProvider] stream, so a guard's check-in shows up without a
/// refresh.
class FrequentVisitDetailScreen extends ConsumerStatefulWidget {
  const FrequentVisitDetailScreen({super.key, required this.visitId});

  final String visitId;

  @override
  ConsumerState<FrequentVisitDetailScreen> createState() =>
      _FrequentVisitDetailScreenState();
}

class _FrequentVisitDetailScreenState
    extends ConsumerState<FrequentVisitDetailScreen> {
  bool _isCancelling = false;

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
            const GatesSheetHeader(title: 'Cancelar acceso'),
            const SizedBox(height: GatesSpacing.space8),
            Text(
              '${visit.name ?? 'Tu visita'} ya no podrá ingresar con este acceso frecuente.',
              style: GatesTypography.body,
            ),
            const SizedBox(height: GatesSpacing.space24),
            SizedBox(
              width: double.infinity,
              child: GatesButton(
                label: 'Sí, cancelar acceso',
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
      await ref.read(visitsRepositoryProvider).cancelFrequentVisit(visit.id);
      if (!mounted) return;
      showGatesToast(
        context,
        type: GatesToastType.success,
        title: 'Acceso cancelado',
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      showGatesToast(
        context,
        type: GatesToastType.error,
        title: 'No pudimos cancelar el acceso',
        message: 'Intenta de nuevo.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final membership = ref.watch(selectedMembershipProvider).value;
    if (membership == null) return const Scaffold(body: LoadingView());

    final visitsAsync = ref.watch(visitsListProvider(membership.unitId));
    final visit = visitsAsync.value
        ?.where((v) => v.id == widget.visitId)
        .firstOrNull;
    if (visit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso frecuente')),
        body: visitsAsync.hasError
            ? ErrorView(
                message: 'No se pudo cargar el acceso.',
                onRetry: () =>
                    ref.invalidate(visitsListProvider(membership.unitId)),
              )
            : const LoadingView(),
      );
    }

    final isActive =
        visit.status == VisitStatus.scheduled ||
        visit.status == VisitStatus.active ||
        visit.status == VisitStatus.inside;
    final movement = isActive
        ? ref.watch(lastMovementProvider(visit.id)).value
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Acceso frecuente'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(GatesSpacing.space24),
          children: [
            Text(
              isActive
                  ? 'Tu visita puede ingresar en los días y horarios que definiste.'
                  : 'Este acceso ya no está disponible.',
              style: GatesTypography.body.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: GatesSpacing.space24),
            _SummaryCard(
              visit: visit,
              isActive: isActive,
              unitName: membership.unitName,
              movement: movement,
            ),
          ],
        ),
      ),
      bottomNavigationBar: isActive
          ? SafeArea(
              minimum: const EdgeInsets.all(GatesSpacing.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GatesTextAction(
                    label: 'Editar acceso',
                    filled: true,
                    onPressed: _isCancelling
                        ? null
                        : () => context.push(
                            '/visits/${visit.id}/access/edit',
                            extra: visit,
                          ),
                  ),
                  const SizedBox(height: 20),
                  GatesTextAction(
                    label: 'Cancelar acceso',
                    color: context.palette.statusError,
                    onPressed: _isCancelling ? null : () => _cancel(visit),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

/// Same card treatment as FastLane's "Invitación / Resumen y estado": a bordered
/// white card with a headline, a status pill and label/value rows.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.visit,
    required this.isActive,
    required this.unitName,
    required this.movement,
  });

  final Visit visit;
  final bool isActive;
  final String unitName;
  final AccessMovement? movement;

  @override
  Widget build(BuildContext context) {
    final role = visit.visitorRole == null
        ? null
        : visitorRoleLabel(visit.visitorRole!);
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
            role == null ? 'Visita' : 'Visita · $role',
            style: context.gatesText.caption.copyWith(fontSize: 13),
          ),
          const SizedBox(height: GatesSpacing.space4),
          Text(
            visit.name ?? 'Sin nombre',
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
              color: isActive
                  ? context.palette.statusSuccessBg
                  : context.palette.bgSubtle,
              borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
            ),
            child: Text(
              isActive ? 'Acceso activo' : visitStatusLabel(visit.status),
              style: context.gatesText.caption.copyWith(
                color: isActive
                    ? context.palette.statusSuccess
                    : context.palette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 10),
            Text(
              'Vigente hasta que lo canceles.',
              style: GatesTypography.body.copyWith(
                fontSize: 14,
                color: context.palette.textSecondary,
                height: 21 / 14,
              ),
            ),
          ],
          _Row(label: 'Días y horario', value: frequentScheduleSummary(visit)),
          _Row(label: 'Unidad', value: unitName),
          if (visit.hasVehicle && (visit.plate ?? '').isNotEmpty)
            _Row(label: 'Vehículo', value: visit.plate!),
          if (movement != null)
            _Row(
              label: 'Último movimiento',
              value: lastMovementLabel(movement!),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.gatesText.caption),
          const SizedBox(height: GatesSpacing.space4),
          Text(
            value,
            style: GatesTypography.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.palette.textSecondary,
              height: 20 / 13,
            ),
          ),
        ],
      ),
    );
  }
}
