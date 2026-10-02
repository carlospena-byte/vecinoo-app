import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_sheet.dart';
import '../../../l10n/l10n.dart';
import '../domain/amenity.dart';
import 'amenity_formatters.dart';

/// "Términos y condiciones" bottom sheet — Figma "A05" / "B13".
Future<void> showTermsSheet(BuildContext context, String terms) {
  return showGatesSheet(
    context,
    (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(GatesSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GatesSheetHeader(title: context.l10n.amenitiesTerms),
            const SizedBox(height: GatesSpacing.space12),
            Flexible(
              child: SingleChildScrollView(
                child: Html(
                  data: terms,
                  style: {
                    'body': Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      color: context.palette.textPrimary,
                    ),
                    'a': Style(color: context.palette.textBrand),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// "Costo de la reserva" detail bottom sheet — Figma "B12 · Detalle del costo".
Future<void> showCostDetailsSheet(BuildContext context, Amenity amenity) {
  final hasCost = amenity.requiresPayment && amenity.price != null;
  return showGatesSheet(context, (context) {
    final currency = amenity.price != null
        ? '\$${amenity.price!.toStringAsFixed(2)}'
        : context.l10n.amenitiesNoCost;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(GatesSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GatesSheetHeader(title: context.l10n.amenitiesCostHeading),
            const SizedBox(height: GatesSpacing.space16),
            Text(
              hasCost ? currency : context.l10n.amenitiesNoCost,
              style: GatesTypography.headingMedium,
            ),
            if (hasCost && amenity.bookingDurationMinutes != null) ...[
              const SizedBox(height: GatesSpacing.space8),
              Text(
                context.l10n.amenitiesPerBookingOf(
                  amenityDurationLabel(
                    context.l10n,
                    amenity.bookingDurationMinutes!,
                  ),
                ),
                style: context.gatesText.labelSecondary,
              ),
            ],
            if (hasCost && amenity.paymentMethods.isNotEmpty) ...[
              const SizedBox(height: GatesSpacing.space16),
              Text(
                context.l10n.amenitiesAcceptedMethods,
                style: GatesTypography.label,
              ),
              const SizedBox(height: 4),
              Text(
                amenity.paymentMethods
                    .map((m) => amenityPaymentMethodLabel(context.l10n, m))
                    .join(' · '),
                style: context.gatesText.labelSecondary,
              ),
            ],
            const SizedBox(height: GatesSpacing.space16),
            Text(
              context.l10n.amenitiesCostInfoNote,
              style: context.gatesText.labelSecondary,
            ),
          ],
        ),
      ),
    );
  });
}

/// "Notas (opcional)" edit bottom sheet — Figma "B11 · Editar notas".
Future<String?> showEditNotesSheet(
  BuildContext context, {
  String? initialNotes,
}) {
  final controller = TextEditingController(text: initialNotes);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(GatesRadius.radius24),
      ),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(GatesSpacing.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GatesSheetHeader(title: context.l10n.amenitiesNotesOptional),
              const SizedBox(height: GatesSpacing.space16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: context.l10n.amenitiesNotesHint,
                ),
                autofocus: true,
              ),
              const SizedBox(height: GatesSpacing.space24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.l10n.amenitiesCancel),
                    ),
                  ),
                  const SizedBox(width: GatesSpacing.space12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(controller.text.trim()),
                      child: Text(context.l10n.amenitiesSave),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
