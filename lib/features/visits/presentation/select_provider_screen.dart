import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_segmented_tabs.dart';
import '../../../core/widgets/gates_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/provider_catalog_item.dart';
import '../domain/visit.dart';
import 'providers_catalog_controller.dart';
import 'visit_details_screen.dart';

String _catalogTitle(ProviderKind kind) =>
    kind == ProviderKind.proveedor ? 'Elige un servicio' : 'Elige una empresa';

/// "07 · Visitas / Catálogos globales" — Figma nodes C01/C02/C03 (`118:712`,
/// `118:771`, `118:824`) unified into one screen: the kind tabs switch which
/// catalog is shown instead of being three separate frames.
class SelectProviderScreen extends ConsumerStatefulWidget {
  const SelectProviderScreen({super.key, required this.initialKind});

  final ProviderKind initialKind;

  @override
  ConsumerState<SelectProviderScreen> createState() =>
      _SelectProviderScreenState();
}

class _SelectProviderScreenState extends ConsumerState<SelectProviderScreen> {
  late ProviderKind _kind = widget.initialKind;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetails(BuildContext context, {ProviderCatalogItem? provider}) {
    context.push(
      '/visits/new/delivery/details',
      extra: VisitDetailsArgs(kind: _kind, provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membership = ref.watch(selectedMembershipProvider).value;
    if (membership == null) return const LoadingView();

    final catalogAsync = ref.watch(
      providersCatalogProvider((
        residentialId: membership.residentialId,
        kind: _kind,
      )),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            GatesSpacing.space24,
            GatesSpacing.space16,
            GatesSpacing.space24,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: GatesSpacing.space12),
                  Expanded(
                    child: Text(
                      _catalogTitle(_kind),
                      style: GatesTypography.headingMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GatesTextField(
                label: 'Buscar',
                hintText: 'Servicio o proveedor',
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
              ),
              const SizedBox(height: GatesSpacing.space16),
              GatesSegmentedTabs<ProviderKind>(
                options: [
                  for (final kind in ProviderKind.values)
                    GatesSegmentedTabOption(
                      value: kind,
                      label: providerKindLabel(kind),
                    ),
                ],
                selected: _kind,
                onSelect: (kind) => setState(() => _kind = kind),
              ),
              const SizedBox(height: GatesSpacing.space16),
              SizedBox(
                width: double.infinity,
                child: GatesButton(
                  style: GatesButtonStyle.secondary,
                  label: 'Otro',
                  onPressed: () => _openDetails(context),
                ),
              ),
              const SizedBox(height: GatesSpacing.space16),
              Expanded(
                child: catalogAsync.when(
                  loading: () => const LoadingView(),
                  error: (e, _) => ErrorView(
                    message: 'No pudimos cargar el catálogo.',
                    onRetry: () => ref.invalidate(
                      providersCatalogProvider((
                        residentialId: membership.residentialId,
                        kind: _kind,
                      )),
                    ),
                  ),
                  data: (items) {
                    final filtered = _query.isEmpty
                        ? items
                        : items
                              .where(
                                (i) => i.name.toLowerCase().contains(_query),
                              )
                              .toList();

                    if (filtered.isEmpty) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: GatesSpacing.space16),
                          Text(
                            'No encontramos resultados',
                            style: GatesTypography.headingSmall,
                          ),
                          const SizedBox(height: GatesSpacing.space8),
                          Text(
                            'Puedes registrar la visita con un nombre personalizado.',
                            style: GatesTypography.labelSecondary,
                          ),
                          const SizedBox(height: GatesSpacing.space16),
                          GatesButton(
                            label: 'Registrar con nombre personalizado',
                            onPressed: () => _openDetails(context),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(
                        bottom: GatesSpacing.space24,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: GatesSpacing.space16),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _CatalogOptionTile(
                          item: item,
                          onTap: () => _openDetails(context, provider: item),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Visitas / Opción de catálogo" — Figma node `117:181`.
class _CatalogOptionTile extends StatelessWidget {
  const _CatalogOptionTile({required this.item, required this.onTap});

  final ProviderCatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(GatesRadius.radius16),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.all(GatesSpacing.space16),
        decoration: BoxDecoration(
          color: GatesColors.bgSurface,
          borderRadius: BorderRadius.circular(GatesRadius.radius16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GatesColors.bgSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                providerInitials(item.name),
                style: GatesTypography.headingSmall.copyWith(
                  color: GatesColors.textBrand,
                ),
              ),
            ),
            const SizedBox(width: GatesSpacing.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: GatesTypography.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: GatesSpacing.space4),
                  Text(
                    providerKindLabel(item.kind),
                    style: GatesTypography.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
