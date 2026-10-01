import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'gates_sheet.dart';

class GatesCountryCode {
  const GatesCountryCode(this.flag, this.name, this.dialCode);

  final String flag;
  final String name;
  final String dialCode;
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
class GatesPhoneField extends StatelessWidget {
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
            const GatesSheetHeader(title: 'País'),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final c in gatesCountryCodes)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        c.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text(c.name, style: GatesTypography.body),
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
    if (picked != null) onCountryChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => validator?.call(controller.text),
      builder: (field) {
        final hasError = field.hasError;
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
                      : context.palette.borderDefault,
                ),
                borderRadius: BorderRadius.circular(GatesRadius.radius16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => _pickCountry(context),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      child: Row(
                        children: [
                          Text(
                            country.flag,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: GatesSpacing.space8),
                          Text(country.dialCode, style: GatesTypography.label),
                          const SizedBox(width: GatesSpacing.space8),
                          const Icon(Icons.keyboard_arrow_down, size: 16),
                        ],
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
                          Text(
                            'Teléfono',
                            style: context.gatesText.caption.copyWith(
                              color: hasError
                                  ? context.palette.statusError
                                  : context.palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: GatesSpacing.space4),
                          TextField(
                            controller: controller,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9 \-]'),
                              ),
                            ],
                            onChanged: (_) => field.didChange(controller.text),
                            style: GatesTypography.body,
                            cursorColor: context.palette.borderFocus,
                            decoration: InputDecoration(
                              isDense: true,
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: hintText,
                              hintStyle: GatesTypography.body.copyWith(
                                color: context.palette.textSecondary,
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
              Text(
                field.errorText!,
                style: context.gatesText.caption.copyWith(
                  color: context.palette.statusError,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
