import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_full_width_image.dart';
import '../../../core/widgets/gates_html.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/l10n.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/bulletin.dart';
import 'bulletin_media_screens.dart';
import 'bulletins_controller.dart';

final _dateFormat = DateFormat("d 'de' MMMM y, HH:mm", 'es');

/// One bulletin, laid out edge to edge: title and rich description with the
/// page margins, images at the full screen width (tap to zoom) and PDFs that
/// open in an in-app reader. Opening it moves it from "Nuevos" to
/// "Historial". Also the target of the "new bulletin" push notification.
class BulletinDetailScreen extends ConsumerStatefulWidget {
  const BulletinDetailScreen({super.key, required this.bulletinId});

  final String bulletinId;

  @override
  ConsumerState<BulletinDetailScreen> createState() =>
      _BulletinDetailScreenState();
}

class _BulletinDetailScreenState extends ConsumerState<BulletinDetailScreen> {
  @override
  void initState() {
    super.initState();
    _markRead();
  }

  /// Marked once the bulletin actually loads, so a failed open stays "new".
  Future<void> _markRead() async {
    try {
      await ref.read(bulletinDetailProvider(widget.bulletinId).future);
      final membership = await ref.read(selectedMembershipProvider.future);
      if (!mounted || membership == null) return;
      await ref
          .read(bulletinReadIdsProvider(membership.residentialId).notifier)
          .markRead(widget.bulletinId);
    } on Exception {
      // The screen already shows the load error; nothing to mark.
    }
  }

  @override
  Widget build(BuildContext context) {
    final bulletinId = widget.bulletinId;
    final bulletinAsync = ref.watch(bulletinDetailProvider(bulletinId));
    final attachments =
        ref.watch(bulletinAttachmentsProvider(bulletinId)).value ?? const [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(context.l10n.bulletinsDetailTitle),
      ),
      body: bulletinAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: context.l10n.bulletinsDetailLoadError,
          onRetry: () {
            ref.invalidate(bulletinDetailProvider(bulletinId));
            ref.invalidate(bulletinAttachmentsProvider(bulletinId));
            _markRead();
          },
        ),
        data: (bulletin) => ListView(
          padding: EdgeInsets.only(
            bottom: GatesSpacing.space24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _BulletinContent(bulletin: bulletin, attachments: attachments),
          ],
        ),
      ),
    );
  }
}

class _BulletinContent extends StatelessWidget {
  const _BulletinContent({required this.bulletin, required this.attachments});

  final Bulletin bulletin;
  final List<BulletinAttachment> attachments;

  static const _margin = EdgeInsets.symmetric(horizontal: GatesSpacing.space24);

  @override
  Widget build(BuildContext context) {
    final description = bulletin.description;
    final images = attachments
        .where((a) => a.kind == BulletinAttachmentKind.image)
        .toList();
    final pdfs = attachments
        .where((a) => a.kind == BulletinAttachmentKind.pdf)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: _margin,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.bulletinsPublishedOn(
                  _dateFormat.format(bulletin.publishedAt),
                ),
                style: context.gatesText.caption,
              ),
              const SizedBox(height: GatesSpacing.space4),
              Text(bulletin.title, style: GatesTypography.headingSmall),
              if (description != null && description.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                GatesHtml(description),
              ],
            ],
          ),
        ),
        if (images.isNotEmpty) ...[
          const SizedBox(height: 20),
          for (final (i, image) in images.indexed) ...[
            if (i > 0) const SizedBox(height: GatesSpacing.space8),
            GatesFullWidthImage(
              url: image.url,
              semanticLabel: context.l10n.bulletinsAttachedImage,
              semanticHint: context.l10n.bulletinsAttachedImageHint,
            ),
          ],
        ],
        if (pdfs.isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: _margin,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.bulletinsDocumentsSection,
                  style: context.gatesText.caption,
                ),
                const SizedBox(height: GatesSpacing.space8),
                for (final pdf in pdfs) ...[
                  _PdfTile(attachment: pdf),
                  const SizedBox(height: GatesSpacing.space8),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PdfTile extends StatelessWidget {
  const _PdfTile({required this.attachment});

  final BulletinAttachment attachment;

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BulletinPdfScreen(
          url: attachment.url,
          fileName: attachment.fileName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: attachment.fileName,
      hint: context.l10n.bulletinsOpenPdfHint,
      excludeSemantics: true,
      onTap: () => _open(context),
      child: Material(
        color: context.palette.bgSubtle,
        borderRadius: BorderRadius.circular(GatesRadius.radius16),
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(GatesRadius.radius16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GatesSpacing.space16,
                vertical: GatesSpacing.space12,
              ),
              child: Row(
                children: [
                  Icon(
                    TablerIcons.fileTypePdf,
                    color: context.palette.textBrand,
                  ),
                  const SizedBox(width: GatesSpacing.space12),
                  Expanded(
                    child: Text(
                      attachment.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GatesTypography.label,
                    ),
                  ),
                  const SizedBox(width: GatesSpacing.space8),
                  Icon(
                    TablerIcons.chevronRight,
                    size: 18,
                    color: context.palette.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
