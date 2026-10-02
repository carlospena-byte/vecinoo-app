import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../theme/app_theme.dart';

/// A network image at 100% of the available width, keeping its own aspect
/// ratio. Tapping opens [GatesImageViewerScreen] (full screen, pinch zoom).
class GatesFullWidthImage extends StatelessWidget {
  const GatesFullWidthImage({
    super.key,
    required this.url,
    required this.semanticLabel,
    required this.semanticHint,
  });

  final String url;
  final String semanticLabel;
  final String semanticHint;

  static const _placeholderHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: double.infinity,
      height: _placeholderHeight,
      color: context.palette.bgSubtle,
    );
    return Semantics(
      button: true,
      label: semanticLabel,
      hint: semanticHint,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                GatesImageViewerScreen(url: url, title: semanticLabel),
          ),
        ),
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : placeholder,
          errorBuilder: (_, _, _) => Container(
            width: double.infinity,
            height: _placeholderHeight,
            color: context.palette.bgSubtle,
            child: Icon(
              TablerIcons.photoOff,
              color: context.palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen, pinch-to-zoom view of one image.
class GatesImageViewerScreen extends StatelessWidget {
  const GatesImageViewerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SizedBox.expand(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              TablerIcons.photoOff,
              color: context.palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
