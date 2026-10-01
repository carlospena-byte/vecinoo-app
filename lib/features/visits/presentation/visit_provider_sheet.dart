import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_segmented_tabs.dart';
import '../../../core/widgets/gates_sheet.dart';
import '../../../core/widgets/gates_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/l10n.dart';
import '../domain/provider_catalog_item.dart';
import '../domain/visit.dart';
import 'providers_catalog_controller.dart';

class ProviderChoice {
  const ProviderChoice(this.kind, this.provider, [this.customName = '']);

  final ProviderKind kind;

  /// Null means "Otro": the resident typed [customName] instead.
  final ProviderCatalogItem? provider;
  final String customName;
}

/// Bottom sheet listing every catalog option (with kind tabs) plus an "Otro"
/// entry that expands an input for a custom name, so a wrong "¿Quién viene?"
/// pick can be changed without going back.
class ProviderSheet extends ConsumerStatefulWidget {
  const ProviderSheet({
    super.key,
    required this.residentialId,
    required this.initialKind,
    required this.selectedId,
    required this.customName,
  });

  final String residentialId;
  final ProviderKind initialKind;
  final String? selectedId;

  /// Name already typed under "Otro" (empty if none).
  final String customName;

  @override
  ConsumerState<ProviderSheet> createState() => ProviderSheetState();
}

class ProviderSheetState extends ConsumerState<ProviderSheet> {
  late ProviderKind _kind = widget.initialKind;
  late final _nameController = TextEditingController(text: widget.customName);

  /// Whether "Otro" is expanded. Starts open when nothing from the catalog is
  /// selected (arrived via "Otro", or already using a custom name).
  late bool _otherOpen = widget.selectedId == null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _confirmOther() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(ProviderChoice(_kind, null, name));
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(
      providersCatalogProvider((
        residentialId: widget.residentialId,
        kind: _kind,
      )),
    );
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: (MediaQuery.sizeOf(context).height * 0.75 - keyboard)
              .clamp(320.0, double.infinity),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GatesSpacing.space24)
              .copyWith(bottom: GatesSpacing.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GatesSheetHeader(title: context.l10n.visitsDetailsChange),
              const SizedBox(height: GatesSpacing.space8),
              GatesSegmentedTabs<ProviderKind>(
                options: [
                  for (final kind in ProviderKind.values)
                    GatesSegmentedTabOption(
                      value: kind,
                      label: providerKindLabel(context.l10n, kind),
                    ),
                ],
                selected: _kind,
                onSelect: (kind) => setState(() => _kind = kind),
              ),
              const SizedBox(height: GatesSpacing.space8),
              Expanded(
                child: catalogAsync.when(
                  loading: () => const LoadingView(),
                  error: (e, _) => ErrorView(
                    message: context.l10n.visitsCatalogLoadError,
                    onRetry: () => ref.invalidate(
                      providersCatalogProvider((
                        residentialId: widget.residentialId,
                        kind: _kind,
                      )),
                    ),
                  ),
                  data: (items) => ListView(
                    children: [
                      for (final item in items)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.palette.bgSubtle,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              providerInitials(item.name),
                              style: GatesTypography.label.copyWith(
                                color: context.palette.textBrand,
                              ),
                            ),
                          ),
                          title: Text(item.name, style: GatesTypography.body),
                          trailing: item.id == widget.selectedId
                              ? Icon(
                                  TablerIcons.check,
                                  color: context.palette.textBrand,
                                )
                              : null,
                          onTap: () =>
                              Navigator.of(context)
                                  .pop(ProviderChoice(_kind, item)),
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(TablerIcons.pencil),
                        ),
                        title: Text(
                          context.l10n.visitsCatalogOther,
                          style: GatesTypography.body,
                        ),
                        trailing: Icon(
                          _otherOpen
                              ? TablerIcons.chevronUp
                              : TablerIcons.chevronDown,
                          color: context.palette.textSecondary,
                        ),
                        onTap: () => setState(() => _otherOpen = !_otherOpen),
                      ),
                      if (_otherOpen) ...[
                        GatesTextField(
                          label: context.l10n.visitsFrequentNameLabel,
                          hintText: context.l10n.visitsDetailsNameHint,
                          autofocus: true,
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: GatesSpacing.space16),
                        GatesButton(
                          label: context.l10n.visitsDetailsUseName,
                          onPressed: _nameController.text.trim().isEmpty
                              ? null
                              : _confirmOther,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
