import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

/// Renders the rich-text subset written in the editors (p, strong, em, ul/ol,
/// a) with the app's typography. Links open in the system browser.
class GatesHtml extends StatelessWidget {
  const GatesHtml(this.data, {super.key});

  final String data;

  @override
  Widget build(BuildContext context) {
    return Html(
      data: data,
      onLinkTap: (url, _, _) {
        final uri = url == null ? null : Uri.tryParse(url);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      style: {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontFamily: 'Manrope',
          fontSize: FontSize(16),
          lineHeight: const LineHeight(24 / 16),
          color: context.palette.textPrimary,
        ),
        'p': Style(margin: Margins.only(bottom: 4)),
        'ul': Style(margin: Margins.zero, padding: HtmlPaddings.only(left: 16)),
        'ol': Style(margin: Margins.zero, padding: HtmlPaddings.only(left: 16)),
        'li': Style(padding: HtmlPaddings.zero),
        'a': Style(color: context.palette.textBrand),
      },
    );
  }
}
