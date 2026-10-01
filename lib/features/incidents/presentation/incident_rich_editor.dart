import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_sheet.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/gates_text_field.dart';
import '../../../l10n/l10n.dart';

const _bold = 1;
const _italic = 2;
const _bullet = '• ';

/// Text controller that keeps per-character formatting (bold, italic, link)
/// next to the plain text, so the field shows it live (WYSIWYG) and it can be
/// serialized to a sanitized HTML subset on save.
class RichTextController extends TextEditingController {
  final List<int> _flags = [];
  final List<String?> _links = [];

  /// Formatting for the next typed characters when the caret is collapsed and
  /// the user toggled a style; null means "inherit from the previous char".
  int? _typing;

  @override
  set value(TextEditingValue newValue) {
    final old = text;
    if (old != newValue.text) {
      _applyDiff(old, newValue.text);
      _typing = null;
    } else if (newValue.selection != selection) {
      _typing = null;
    }
    super.value = newValue;
  }

  void _applyDiff(String old, String next) {
    var prefix = 0;
    final minLen = old.length < next.length ? old.length : next.length;
    while (prefix < minLen &&
        old.codeUnitAt(prefix) == next.codeUnitAt(prefix)) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < minLen - prefix &&
        old.codeUnitAt(old.length - 1 - suffix) ==
            next.codeUnitAt(next.length - 1 - suffix)) {
      suffix++;
    }
    final removed = old.length - prefix - suffix;
    final inserted = next.length - prefix - suffix;
    final inheritedFlags = prefix > 0 ? _flags[prefix - 1] : 0;
    final inheritedLink = prefix > 0 ? _links[prefix - 1] : null;
    _flags.removeRange(prefix, prefix + removed);
    _links.removeRange(prefix, prefix + removed);
    final flags = _typing ?? inheritedFlags;
    // Typing right after a link continues it; typing with a pending style
    // toggle does not.
    final link = _typing == null ? inheritedLink : null;
    _flags.insertAll(prefix, List.filled(inserted, flags));
    _links.insertAll(prefix, List.filled(inserted, link));
  }

  /// Loads content saved by [toHtml] (or legacy plain text) back into the
  /// editor, keeping bold / italic / links / bullets.
  void loadHtml(String? html) {
    final source = html ?? '';
    final buffer = StringBuffer();
    final flags = <int>[];
    final links = <String?>[];
    var bold = 0, italic = 0;
    final linkStack = <String?>[];
    var needsBreak = false;

    void write(String chars) {
      var f = 0;
      if (bold > 0) f |= _bold;
      if (italic > 0) f |= _italic;
      final link = linkStack.isEmpty ? null : linkStack.last;
      buffer.write(chars);
      for (var i = 0; i < chars.length; i++) {
        flags.add(f);
        links.add(link);
      }
    }

    void startBlock(String prefix) {
      if (needsBreak) write('\n');
      needsBreak = true;
      if (prefix.isNotEmpty) {
        final saved = (bold, italic);
        bold = 0;
        italic = 0;
        write(prefix);
        bold = saved.$1;
        italic = saved.$2;
      }
    }

    if (!source.contains(RegExp(r'<(p|ul|li|strong|em|a)[ >/]'))) {
      write(_unescape(source));
    } else {
      final token = RegExp(r'<(/?)(\w+)([^>]*)>|([^<]+)');
      for (final m in token.allMatches(source)) {
        final textPart = m.group(4);
        if (textPart != null) {
          write(_unescape(textPart));
          continue;
        }
        final closing = m.group(1) == '/';
        switch (m.group(2)) {
          case 'p':
            if (!closing) startBlock('');
          case 'li':
            if (!closing) startBlock(_bullet);
          case 'strong' || 'b':
            bold += closing ? -1 : 1;
          case 'em' || 'i':
            italic += closing ? -1 : 1;
          case 'a':
            if (closing) {
              if (linkStack.isNotEmpty) linkStack.removeLast();
            } else {
              final href = RegExp(r'href="([^"]*)"').firstMatch(m.group(3)!);
              final url = href == null ? null : _unescape(href.group(1)!);
              linkStack.add(url != null && _isSafeUrl(url) ? url : null);
            }
        }
      }
    }

    _flags
      ..clear()
      ..addAll(flags);
    _links
      ..clear()
      ..addAll(links);
    _typing = null;
    super.value = TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }

  static String _unescape(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&');

  bool isActive(int flag) {
    final sel = selection;
    if (!sel.isValid) return false;
    if (sel.isCollapsed) {
      final current = _typing ?? (sel.start > 0 ? _flags[sel.start - 1] : 0);
      return current & flag != 0;
    }
    for (var i = sel.start; i < sel.end; i++) {
      if (_flags[i] & flag == 0) return false;
    }
    return true;
  }

  void toggle(int flag) {
    final sel = selection;
    if (!sel.isValid) return;
    if (sel.isCollapsed) {
      final current = _typing ?? (sel.start > 0 ? _flags[sel.start - 1] : 0);
      _typing = current ^ flag;
    } else {
      final on = !isActive(flag);
      for (var i = sel.start; i < sel.end; i++) {
        _flags[i] = on ? _flags[i] | flag : _flags[i] & ~flag;
      }
    }
    notifyListeners();
  }

  void toggleBold() => toggle(_bold);
  void toggleItalic() => toggle(_italic);
  bool get isBold => isActive(_bold);
  bool get isItalic => isActive(_italic);

  /// Adds or removes the "• " prefix on the line holding the caret.
  void toggleBullet() {
    final sel = selection;
    final offset = sel.isValid ? sel.start : text.length;
    final start = offset == 0 ? 0 : text.lastIndexOf('\n', offset - 1) + 1;
    final hasBullet = text.startsWith(_bullet, start);
    _typing = 0;
    if (hasBullet) {
      value = TextEditingValue(
        text: text.replaceRange(start, start + _bullet.length, ''),
        selection: TextSelection.collapsed(
          offset: (offset - _bullet.length).clamp(start, text.length),
        ),
      );
    } else {
      value = TextEditingValue(
        text: text.replaceRange(start, start, _bullet),
        selection: TextSelection.collapsed(offset: offset + _bullet.length),
      );
    }
  }

  bool get isBullet {
    final sel = selection;
    final offset = sel.isValid ? sel.start : text.length;
    final start = offset == 0 ? 0 : text.lastIndexOf('\n', offset - 1) + 1;
    return text.startsWith(_bullet, start);
  }

  /// Links the selected text; with a collapsed caret, inserts [url] itself.
  void applyLink(String url) {
    final sel = selection;
    final at = sel.isValid ? sel.start : text.length;
    if (!sel.isValid || sel.isCollapsed) {
      _typing = 0;
      value = TextEditingValue(
        text: text.replaceRange(at, at, url),
        selection: TextSelection.collapsed(offset: at + url.length),
      );
      for (var i = at; i < at + url.length; i++) {
        _links[i] = url;
      }
    } else {
      for (var i = sel.start; i < sel.end; i++) {
        _links[i] = url;
      }
    }
    notifyListeners();
  }

  bool get hasSelection => selection.isValid && !selection.isCollapsed;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (text.isEmpty) return TextSpan(style: style, text: text);
    final spans = <InlineSpan>[];
    var runStart = 0;
    for (var i = 1; i <= text.length; i++) {
      final boundary =
          i == text.length ||
          _flags[i] != _flags[runStart] ||
          _links[i] != _links[runStart];
      if (!boundary) continue;
      final flags = _flags[runStart];
      final link = _links[runStart];
      spans.add(
        TextSpan(
          text: text.substring(runStart, i),
          style: TextStyle(
            fontWeight: flags & _bold != 0 ? FontWeight.w700 : null,
            fontStyle: flags & _italic != 0 ? FontStyle.italic : null,
            color: link != null ? context.palette.textBrand : null,
            decoration: link != null ? TextDecoration.underline : null,
          ),
        ),
      );
      runStart = i;
    }
    return TextSpan(style: style, children: spans);
  }

  /// Sanitized HTML subset (`p`, `strong`, `em`, `a`, `ul`/`li`) or null when
  /// there is no content. Everything is escaped and links are limited to
  /// http(s)/mailto, so nothing else can reach the backend.
  String? toHtml() {
    if (text.trim().isEmpty) return null;
    final out = StringBuffer();
    var inList = false;
    var offset = 0;
    for (final line in text.split('\n')) {
      final isBullet = line.startsWith(_bullet);
      final contentStart = offset + (isBullet ? _bullet.length : 0);
      final content = _inlineHtml(contentStart, offset + line.length);
      if (isBullet) {
        if (!inList) out.write('<ul>');
        inList = true;
        out.write('<li>$content</li>');
      } else {
        if (inList) out.write('</ul>');
        inList = false;
        if (line.trim().isNotEmpty) out.write('<p>$content</p>');
      }
      offset += line.length + 1;
    }
    if (inList) out.write('</ul>');
    return out.toString();
  }

  String _inlineHtml(int from, int to) {
    final out = StringBuffer();
    var runStart = from;
    for (var i = from + 1; i <= to; i++) {
      final boundary =
          i == to ||
          _flags[i] != _flags[runStart] ||
          _links[i] != _links[runStart];
      if (!boundary || i == runStart) continue;
      var piece = _escape(text.substring(runStart, i));
      final flags = _flags[runStart];
      final link = _links[runStart];
      if (flags & _bold != 0) piece = '<strong>$piece</strong>';
      if (flags & _italic != 0) piece = '<em>$piece</em>';
      if (link != null && _isSafeUrl(link)) {
        piece = '<a href="${_escape(link)}">$piece</a>';
      }
      out.write(piece);
      runStart = i;
    }
    return out.toString();
  }

  static String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static bool _isSafeUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' ||
            uri.scheme == 'https' ||
            uri.scheme == 'mailto');
  }
}

/// Figma "Incidencias / Editor enriquecido" (node `461:954`): label, B / I /
/// list / link toolbar and the editable area in a single bordered card.
class IncidentRichEditor extends StatelessWidget {
  const IncidentRichEditor({super.key, required this.controller});

  final RichTextController controller;

  Future<void> _addLink(BuildContext context) async {
    final url = await showGatesSheet<String>(
      context,
      (_) => _LinkSheet(hasSelection: controller.hasSelection),
    );
    if (url != null) controller.applyLink(url);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GatesSpacing.space16),
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        border: Border.all(color: context.palette.borderDefault),
        borderRadius: BorderRadius.circular(GatesRadius.radius16),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.incidentsEditorDescriptionLabel,
              style: GatesTypography.label.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: GatesSpacing.space12),
            Row(
              children: [
                _ToolButton(
                  active: controller.isBold,
                  onTap: controller.toggleBold,
                  semanticLabel: context.l10n.incidentsEditorBold,
                  child: Text(
                    'B',
                    style: GatesTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.palette.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: GatesSpacing.space4),
                _ToolButton(
                  active: controller.isItalic,
                  onTap: controller.toggleItalic,
                  semanticLabel: context.l10n.incidentsEditorItalic,
                  child: Text(
                    'I',
                    style: GatesTypography.body.copyWith(
                      color: context.palette.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: GatesSpacing.space4),
                _ToolButton(
                  active: controller.isBullet,
                  onTap: controller.toggleBullet,
                  semanticLabel: context.l10n.incidentsEditorList,
                  child: Icon(
                    Icons.format_list_bulleted,
                    size: 20,
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(width: GatesSpacing.space4),
                _ToolButton(
                  active: false,
                  onTap: () => _addLink(context),
                  semanticLabel: context.l10n.incidentsEditorLink,
                  child: Icon(
                    Icons.link,
                    size: 20,
                    color: context.palette.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: GatesSpacing.space12),
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: context.gatesText.labelSecondary.copyWith(
                color: context.palette.textPrimary,
              ),
              cursorColor: context.palette.borderFocus,
              decoration: InputDecoration(
                isDense: true,
                isCollapsed: true,
                border: InputBorder.none,
                hintText: context.l10n.incidentsEditorDescriptionHint,
                hintStyle: context.gatesText.labelSecondary.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.active,
    required this.onTap,
    required this.child,
    required this.semanticLabel,
  });

  final bool active;
  final VoidCallback onTap;
  final Widget child;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: semanticLabel,
      child: Material(
        color: active ? context.palette.bgAccent : Colors.transparent,
        borderRadius: BorderRadius.circular(GatesRadius.radius8),
        child: InkWell(
          borderRadius: BorderRadius.circular(GatesRadius.radius8),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _LinkSheet extends StatefulWidget {
  const _LinkSheet({required this.hasSelection});

  final bool hasSelection;

  @override
  State<_LinkSheet> createState() => _LinkSheetState();
}

class _LinkSheetState extends State<_LinkSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    var raw = _controller.text.trim();
    if (raw.isEmpty) return;
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(raw)) {
      raw = 'https://$raw';
    }
    final uri = Uri.tryParse(raw);
    final ok =
        uri != null &&
        (uri.scheme == 'http' ||
            uri.scheme == 'https' ||
            uri.scheme == 'mailto') &&
        (uri.scheme == 'mailto' || uri.host.contains('.'));
    if (!ok) {
      setState(() => _error = context.l10n.incidentsEditorLinkInvalid);
      return;
    }
    Navigator.of(context).pop(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GatesSpacing.space24,
        0,
        GatesSpacing.space24,
        GatesSpacing.space24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GatesSheetHeader(title: context.l10n.incidentsEditorAddLink),
          if (!widget.hasSelection) ...[
            const SizedBox(height: GatesSpacing.space4),
            Text(
              context.l10n.incidentsEditorLinkNoSelection,
              style: context.gatesText.labelSecondary.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: GatesSpacing.space16),
          GatesTextField(
            controller: _controller,
            label: context.l10n.incidentsEditorLink,
            hintText: context.l10n.incidentsEditorLinkHint,
            errorText: _error,
            autofocus: true,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: GatesSpacing.space16),
          GatesButton(
            label: context.l10n.incidentsEditorAddLink,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
