import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/attachment.dart';
import '../services/attachment_store.dart';
import '../theme/app_colors.dart';

/// Opens the platform file picker for ANY file type, uploads the picked file to
/// the shared Supabase Storage bucket, and returns an [Attachment] referencing
/// it (or null if cancelled/unavailable). Reads bytes rather than a filesystem
/// path so it works uniformly on Android/iOS/Web/Windows/macOS/Linux. If the
/// upload fails the returned attachment falls back to inline base64 bytes.
Future<Attachment?> pickAttachment() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    withData: true,
  );
  final file = result?.files.single;
  final bytes = file?.bytes;
  if (file == null || bytes == null) return null;
  return AttachmentStore.upload(file.name, bytes);
}

/// A horizontal strip of attachment tiles. Image attachments render as a
/// thumbnail (tap to preview full-size); every other format (PDF, Word,
/// spreadsheets, …) renders as a labelled file tile showing its extension
/// and name. Each tile has a remove affordance, and an "add file" tile
/// appends more. Used for defect/requisition/daily-task evidence and for
/// certificate document attachments.
class AttachmentPickerStrip extends StatefulWidget {
  final List<Attachment> attachments;
  final ValueChanged<Attachment> onAdd;
  final ValueChanged<int> onRemove;
  final bool multiple;

  const AttachmentPickerStrip({
    super.key,
    required this.attachments,
    required this.onAdd,
    required this.onRemove,
    this.multiple = true,
  });

  @override
  State<AttachmentPickerStrip> createState() => _AttachmentPickerStripState();
}

class _AttachmentPickerStripState extends State<AttachmentPickerStrip> {
  bool _busy = false;

  IconData _iconFor(Attachment a) {
    switch (a.extension) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_outlined;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_outlined;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_outlined;
      case 'txt':
        return Icons.article_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  /// Opens a non-image attachment. PDFs are fetched (from Storage or inline)
  /// then handed to the print/share sheet (downloads on web, opens the
  /// share/print dialog on desktop & mobile); other formats have no in-app
  /// viewer yet.
  Future<void> _openFile(Attachment a) async {
    if (a.extension != 'pdf') return;
    try {
      final bytes = await AttachmentStore.bytes(a);
      await Printing.sharePdf(bytes: bytes, filename: a.name);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${a.name} — download failed')),
        );
      }
    }
  }

  void _previewImage(BuildContext context, Attachment a) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: InteractiveViewer(
                child: _AttachmentImage(a, fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(a.name,
                  style: Theme.of(ctx).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final picked = await pickAttachment();
      if (picked != null) widget.onAdd(picked);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final attachments = widget.attachments;
    final showAddTile = widget.multiple || attachments.isEmpty;

    Widget removeBadge(int index) => Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: () => widget.onRemove(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.statusMaintenance,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        );

    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < attachments.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  if (attachments[i].isImage)
                    InkWell(
                      onTap: () => _previewImage(context, attachments[i]),
                      borderRadius: BorderRadius.circular(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _AttachmentImage(
                          attachments[i],
                          width: 84,
                          height: 84,
                        ),
                      ),
                    )
                  else
                    InkWell(
                      onTap: () => _openFile(attachments[i]),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 84,
                        height: 84,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: dark ? AppColors.navy700 : AppColors.slate100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: dark
                                ? AppColors.navy600
                                : AppColors.slate200,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_iconFor(attachments[i]),
                                size: 26, color: AppColors.teal500),
                            const SizedBox(height: 4),
                            Text(
                              attachments[i].name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 9, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  removeBadge(i),
                ],
              ),
            ),
          if (showAddTile)
            InkWell(
              onTap: _busy ? null : _pick,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: dark ? AppColors.navy700 : AppColors.slate100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: dark ? AppColors.navy600 : AppColors.slate200,
                  ),
                ),
                alignment: Alignment.center,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.upload_file_outlined,
                              color: scheme.onSurface.withValues(alpha: 0.6),
                              size: 22),
                          const SizedBox(height: 4),
                          Text(t.addFile, style: const TextStyle(fontSize: 10)),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Renders an attachment's image bytes, fetching them from Storage (or decoding
/// inline base64) and showing a spinner while a cloud download is in flight.
class _AttachmentImage extends StatelessWidget {
  final Attachment attachment;
  final double? width;
  final double? height;
  final BoxFit fit;

  const _AttachmentImage(
    this.attachment, {
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  Widget _placeholder(BuildContext context, {bool error = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: scheme.surfaceContainerHighest,
      child: error
          ? const Icon(Icons.broken_image_outlined, size: 22)
          : const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cached = AttachmentStore.peek(attachment);
    if (cached != null) {
      return Image.memory(cached, width: width, height: height, fit: fit);
    }
    return FutureBuilder<Uint8List>(
      future: AttachmentStore.bytes(attachment),
      builder: (ctx, snap) {
        if (snap.hasData) {
          return Image.memory(snap.data!,
              width: width, height: height, fit: fit);
        }
        return _placeholder(ctx, error: snap.hasError);
      },
    );
  }
}
