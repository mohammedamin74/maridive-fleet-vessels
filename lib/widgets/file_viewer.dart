import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/attachment.dart';
import '../services/attachment_store.dart';
import '../theme/app_colors.dart';

/// File extensions we can render as plain text in-app.
const Set<String> _textExtensions = {
  'txt', 'csv', 'log', 'json', 'md', 'xml', 'yaml', 'yml', 'ini', 'sql',
};

/// Opens a full-screen viewer for [a]. Images, PDFs and text files render in
/// the app; every other format (Word, Excel, PowerPoint, archives, …) shows a
/// clear "no preview" fail-safe with a Download action, so a tap never dead-ends
/// or crashes. Available on Android/iOS/Web/Windows/macOS/Linux.
Future<void> showAttachmentViewer(BuildContext context, Attachment a) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => FileViewerScreen(attachment: a),
    ),
  );
}

/// Saves [bytes] to the user's device (browser download on web, Downloads/
/// Documents on desktop & mobile) using its original name and extension.
Future<void> downloadAttachment(
    BuildContext context, Attachment a, Uint8List bytes) async {
  final t = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final dot = a.name.lastIndexOf('.');
    final base = dot == -1 ? a.name : a.name.substring(0, dot);
    await FileSaver.instance.saveFile(
      name: base.isEmpty ? 'file' : base,
      bytes: bytes,
      fileExtension: a.extension,
      mimeType: MimeType.other,
    );
    messenger.showSnackBar(SnackBar(content: Text(t.fileSaved)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(t.downloadFailed)));
  }
}

class FileViewerScreen extends StatelessWidget {
  final Attachment attachment;
  const FileViewerScreen({super.key, required this.attachment});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(attachment.name, overflow: TextOverflow.ellipsis),
      ),
      body: FutureBuilder<Uint8List>(
        future: AttachmentStore.bytes(attachment),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return _CenteredMessage(
              icon: Icons.error_outline,
              message: t.downloadFailed,
            );
          }
          return _content(context, t, snap.data!);
        },
      ),
    );
  }

  Widget _content(BuildContext context, AppLocalizations t, Uint8List bytes) {
    final ext = attachment.extension;

    if (attachment.isImage) {
      return _WithDownloadBar(
        attachment: attachment,
        bytes: bytes,
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Center(child: Image.memory(bytes)),
        ),
      );
    }

    if (ext == 'pdf') {
      // PdfPreview renders pages in-app and carries its own share/print toolbar
      // (which downloads on web), so no extra download bar is needed.
      return PdfPreview(
        build: (_) => bytes,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      );
    }

    if (_textExtensions.contains(ext)) {
      String text;
      try {
        text = utf8.decode(bytes);
      } catch (_) {
        text = latin1.decode(bytes, allowInvalid: true);
      }
      return _WithDownloadBar(
        attachment: attachment,
        bytes: bytes,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            text,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
      );
    }

    // Unsupported format — the fail-safe.
    return _UnsupportedPane(attachment: attachment, bytes: bytes);
  }
}

/// Wraps content with a bottom Download button.
class _WithDownloadBar extends StatelessWidget {
  final Attachment attachment;
  final Uint8List bytes;
  final Widget child;
  const _WithDownloadBar({
    required this.attachment,
    required this.bytes,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(child: child),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => downloadAttachment(context, attachment, bytes),
                icon: const Icon(Icons.download_outlined),
                label: Text(t.downloadFile),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shown for formats with no in-app preview (Office docs, archives, …).
class _UnsupportedPane extends StatelessWidget {
  final Attachment attachment;
  final Uint8List bytes;
  const _UnsupportedPane({required this.attachment, required this.bytes});

  IconData get _icon {
    switch (attachment.extension) {
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_outlined;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 64, color: AppColors.teal500),
            const SizedBox(height: 16),
            Text(
              attachment.name,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              t.previewUnavailable,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => downloadAttachment(context, attachment, bytes),
              icon: const Icon(Icons.download_outlined),
              label: Text(t.downloadFile),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  const _CenteredMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.statusMaintenance),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
