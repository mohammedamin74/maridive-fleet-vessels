import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/attachment.dart';
import '../theme/app_colors.dart';

/// Opens the platform file picker for ANY file type and returns the picked
/// file as an [Attachment] (original filename + base64 bytes), or null if
/// cancelled/unavailable. Always reads bytes rather than a filesystem path
/// so it works uniformly on Android/iOS/Web/Windows/macOS/Linux.
Future<Attachment?> pickAttachment() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    withData: true,
  );
  final file = result?.files.single;
  final bytes = file?.bytes;
  if (file == null || bytes == null) return null;
  return Attachment(name: file.name, dataBase64: base64Encode(bytes));
}

/// A horizontal strip of attachment tiles. Image attachments render as a
/// thumbnail (tap to preview full-size); every other format (PDF, Word,
/// spreadsheets, …) renders as a labelled file tile showing its extension
/// and name. Each tile has a remove affordance, and an "add file" tile
/// appends more. Used for defect/requisition/daily-task evidence and for
/// certificate document attachments.
class AttachmentPickerStrip extends StatelessWidget {
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
                child: Image.memory(base64Decode(a.dataBase64)),
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final showAddTile = multiple || attachments.isEmpty;

    Widget removeBadge(int index) => Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: () => onRemove(index),
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
                        child: Image.memory(
                          base64Decode(attachments[i].dataBase64),
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
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
                  removeBadge(i),
                ],
              ),
            ),
          if (showAddTile)
            InkWell(
              onTap: () async {
                final picked = await pickAttachment();
                if (picked != null) onAdd(picked);
              },
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
                child: Column(
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
