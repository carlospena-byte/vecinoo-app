import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'gates_sheet.dart';
import '../../l10n/l10n.dart';

class GatesCountryCode {
  const GatesCountryCode(this.flag, this.name, this.dialCode);

  /// [name] is the Spanish source name; UI should show [localizedName].
  final String flag;
  final String name;
  final String dialCode;

  /// Country name in the current locale (resolved at build time, since this
  /// list is const data with no [BuildContext]).
  String localizedName(BuildContext context) {
    final l10n = context.l10n;
    return switch (dialCode) {
      '+504' => l10n.commonCountryHonduras,
      '+502' => l10n.commonCountryGuatemala,
      '+503' => l10n.commonCountryElSalvador,
      '+505' => l10n.commonCountryNicaragua,
      '+506' => l10n.commonCountryCostaRica,
      '+507' => l10n.commonCountryPanama,
      '+52' => l10n.commonCountryMexico,
      '+1' => l10n.commonCountryUnitedStates,
      _ => name,
    };
  }
}

const gatesCountryCodes = [
  GatesCountryCode('🇭🇳', 'Honduras', '+504'),
  GatesCountryCode('🇬🇹', 'Guatemala', '+502'),
  GatesCountryCode('🇸🇻', 'El Salvador', '+503'),
  GatesCountryCode('🇳🇮', 'Nicaragua', '+505'),
  GatesCountryCode('🇨🇷', 'Costa Rica', '+506'),
  GatesCountryCode('🇵🇦', 'Panamá', '+507'),
  GatesCountryCode('🇲🇽', 'México', '+52'),
  GatesCountryCode('🇺🇸', 'Estados Unidos', '+1'),
];

/// Figma "Input/Phone": country-code chip (opens a picker) + IFTA phone field.
/// [controller] holds only the local number; the caller combines it with
/// [GatesPhoneField.country] when saving.
class GatesPhoneField extends StatefulWidget {
  const GatesPhoneField({
    super.key,
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    this.hintText = '9999-9999',
    this.validator,
  });

  final TextEditingController controller;
  final GatesCountryCode country;
  final ValueChanged<GatesCountryCode> onCountryChanged;
  final String hintText;
  final String? Function(String?)? validator;

  @override
  State<GatesPhoneField> createState() => _GatesPhoneFieldState();
}

class _GatesPhoneFieldState extends State<GatesPhoneField> {
  final _focusNode = FocusNode();

  TextEditingController get controller => widget.controller;
  GatesCountryCode get country => widget.country;
  String get hintText => widget.hintText;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  Future<void> _pickCountry(BuildContext context) async {
    final picked = await showGatesSheet<GatesCountryCode>(
      context,
      (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: GatesSpacing.space24)
            .copyWith(bottom: GatesSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GatesSheetHeader(title: sheetContext.l10n.commonCountry),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final c in gatesCountryCodes)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        c.flag,
                        style: GatesTypography.headingSmall,
                      ),
                      title: Text(
                        c.localizedName(context),
                        style: GatesTypography.body,
                      ),
                      trailing: Text(c.dialCode, style: GatesTypography.label),
                      selected: c.dialCode == country.dialCode,
                      onTap: () => Navigator.of(sheetContext).pop(c),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) widget.onCountryChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => widget.validator?.call(controller.text),
      builder: (field) {
        final hasError = field.hasError;
        final isFocused = _focusNode.hasFocus;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: context.palette.bgSurface,
                border: Border.all(
                  color: hasError
                      ? context.palette.statusError
                      : isFocused
                      ? context.palette.borderFocus
                      : context.palette.borderDefault,
                  width: isFocused ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(GatesRadius.radius16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: context.l10n.commonCountryCode(country.dialCode),
                    excludeSemantics: true,
                    onTap: () => _pickCountry(context),
                    child: InkWell(
                      onTap: () => _pickCountry(context),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 12),
                        child: Row(
                          children: [
                            Text(
                              country.flag,
                              style: GatesTypography.headingSmall,
                            ),
                            const SizedBox(width: GatesSpacing.space8),
                            Text(
                              country.dialCode,
                              style: GatesTypography.label,
                            ),
                            const SizedBox(width: GatesSpacing.space8),
                            const Icon(TablerIcons.chevronDown, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: context.palette.borderDefault,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: Text(
                              context.l10n.commonPhone,
                              style: context.gatesText.caption.copyWith(
                                color: hasError
                                    ? context.palette.statusError
                                    : context.palette.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: GatesSpacing.space4),
                          Semantics(
                            label: context.l10n.commonPhone,
                            child: TextField(
                              controller: controller,
                              focusNode: _focusNode,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9 \-]'),
                                ),
                              ],
                              onChanged: (_) =>
                                  field.didChange(controller.text),
                              style: GatesTypography.body,
                              cursorColor: context.palette.borderFocus,
                              decoration: InputDecoration(
                                isDense: true,
                                isCollapsed: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                hintText: hintText,
                                hintStyle: GatesTypography.body.copyWith(
                                  color: context.palette.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: GatesSpacing.space4),
              Semantics(
                liveRegion: true,
                child: Text(
                  field.errorText!,
                  style: context.gatesText.caption.copyWith(
                    color: context.palette.statusError,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
