import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../l10n/l10n.dart';

/// Figma "Textarea / IFTA": label + multiline field in one bordered box, with
/// a `n/max` counter underneath. Rebuilds itself as [controller] changes.
class GatesTextArea extends StatelessWidget {
  const GatesTextArea({
    super.key,
    required this.controller,
    required this.maxLength,
    this.label,
    this.hintText,
  });

  final TextEditingController controller;
  final int maxLength;

  /// Defaults to the localized "notes for the front desk (optional)".
  final String? label;

  /// Defaults to the localized "add an instruction".
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final label = this.label ?? context.l10n.commonDoormanNotesLabel;
    final hintText = this.hintText ?? context.l10n.commonDoormanNotesHint;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.palette.bgSurface,
              border: Border.all(color: context.palette.borderDefault),
              borderRadius: BorderRadius.circular(GatesRadius.radius16),
            ),
            padding: const EdgeInsets.all(GatesSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Text(label, style: context.gatesText.caption),
                ),
                const SizedBox(height: GatesSpacing.space8),
                Semantics(
                  label: label,
                  child: TextField(
                    controller: controller,
                    maxLines: 4,
                    maxLength: maxLength,
                    textCapitalization: TextCapitalization.sentences,
                    buildCounter: (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                    style: GatesTypography.body,
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
                ),
              ],
            ),
          ),
          const SizedBox(height: GatesSpacing.space4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${controller.text.length}/$maxLength',
              style: context.gatesText.caption,
            ),
          ),
        ],
      ),
    );
  }
}
