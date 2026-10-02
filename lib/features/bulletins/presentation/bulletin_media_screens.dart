import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/l10n.dart';

/// In-app PDF reader for a bulletin document, so residents never leave the
/// app to read it.
class BulletinPdfScreen extends StatelessWidget {
  const BulletinPdfScreen({
    super.key,
    required this.url,
    required this.fileName,
  });

  final String url;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    return Scaffold(
      appBar: AppBar(title: Text(fileName, maxLines: 1)),
      body: uri == null
          ? ErrorView(message: context.l10n.bulletinsOpenFailed)
          : PdfViewer.uri(
              uri,
              params: PdfViewerParams(
                backgroundColor: context.palette.bgSubtle,
                loadingBannerBuilder: (_, _, _) => const LoadingView(),
                errorBannerBuilder: (_, _, _, _) =>
                    ErrorView(message: context.l10n.bulletinsOpenFailed),
              ),
            ),
    );
  }
}
