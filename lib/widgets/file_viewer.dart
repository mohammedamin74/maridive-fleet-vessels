import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xlsx;
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

const Set<String> _spreadsheetExtensions = {'xlsx', 'xls', 'xlsm'};

/// One parsed sheet: name plus its cell grid, trimmed of the fully-blank
/// trailing rows/columns Excel often keeps in the used range.
class _SheetTable {
  final String name;
  final List<List<String>> rows;
  const _SheetTable(this.name, this.rows);
}

/// Parses every sheet into a real grid (for [GridTableView]) instead of
/// flattening it to tab-separated text — a defect/requisition list with
/// mostly-empty rows reads as a table, not a wall of numbers.
List<_SheetTable> _parseSpreadsheet(Uint8List bytes) {
  final book = xlsx.Excel.decodeBytes(bytes);
  final sheets = <_SheetTable>[];
  for (final entry in book.tables.entries) {
    final raw = entry.value.rows
        .map((row) => row.map((c) => c?.value?.toString() ?? '').toList())
        .toList();
    if (raw.isEmpty) continue;

    var width = 0;
    for (final r in raw) {
      if (r.length > width) width = r.length;
    }
    final padded = [
      for (final r in raw) [...r, ...List.filled(width - r.length, '')],
    ];

    var lastRow = -1;
    for (var i = 0; i < padded.length; i++) {
      if (padded[i].any((c) => c.trim().isNotEmpty)) lastRow = i;
    }
    if (lastRow < 0) continue;
    final trimmedRows = padded.sublist(0, lastRow + 1);

    var lastCol = -1;
    for (var c = 0; c < width; c++) {
      if (trimmedRows.any((r) => r[c].trim().isNotEmpty)) lastCol = c;
    }
    final trimmed = [
      for (final r in trimmedRows) r.sublist(0, lastCol + 1),
    ];

    sheets.add(_SheetTable(entry.key, trimmed));
  }
  return sheets;
}

String _decodeXmlEntities(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');

/// A parsed piece of a .docx body: either running text or a table, in
/// document order — so tables render as real grids, not flattened lines.
abstract class _DocxBlock {
  const _DocxBlock();
}

class _DocxParagraphs extends _DocxBlock {
  final String text;
  const _DocxParagraphs(this.text);
}

class _DocxTable extends _DocxBlock {
  /// Rows padded to equal length (merged cells make Word rows ragged).
  final List<List<String>> rows;
  const _DocxTable(this.rows);
}

/// .docx is a zip of XML parts; the visible text lives in `word/document.xml`
/// inside `<w:t>` runs. A regex scan with a small state machine is lighter
/// than a full XML parser: `<w:t` must be followed by whitespace or `>` (a
/// bare `[^>]*` also matched table tags like <w:trPr>, dumping raw XML into
/// the preview), and the self-closing empty-run alternative keeps `<w:t/>`
/// from pairing with a later `</w:t>` and swallowing markup between them.
List<_DocxBlock> _parseDocx(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final doc = archive.files
      .firstWhere((f) => f.name == 'word/document.xml', orElse: () {
    throw const FormatException('word/document.xml not found');
  });
  final xml = utf8.decode(doc.content as List<int>);
  final tagPattern = RegExp(
    r'<w:t(?:\s[^>]*)?/>|<w:t(?:\s[^>]*)?>(.*?)</w:t>|<w:tab\s*/>'
    r'|<w:tbl(?:\s[^>]*)?>|</w:tbl>|</w:tc>|</w:tr>|</w:p>',
    dotAll: true,
  );

  final blocks = <_DocxBlock>[];
  final para = StringBuffer();
  final cell = StringBuffer();
  var row = <String>[];
  var rows = <List<String>>[];
  var tableDepth = 0;

  void flushPara() {
    final text = _decodeXmlEntities(para.toString()).trim();
    para.clear();
    if (text.isNotEmpty) blocks.add(_DocxParagraphs(text));
  }

  for (final m in tagPattern.allMatches(xml)) {
    final tag = m.group(0)!;
    final inTable = tableDepth > 0;
    if (m.group(1) != null) {
      (inTable ? cell : para).write(m.group(1));
    } else if (tag.startsWith('<w:tab')) {
      (inTable ? cell : para).write('\t');
    } else if (tag.startsWith('<w:tbl')) {
      if (!inTable) flushPara();
      tableDepth++;
    } else if (tag == '</w:tbl>') {
      if (tableDepth > 0) tableDepth--;
      if (tableDepth == 0 && rows.isNotEmpty) {
        var width = 0;
        for (final r in rows) {
          if (r.length > width) width = r.length;
        }
        blocks.add(_DocxTable([
          for (final r in rows) [...r, ...List.filled(width - r.length, '')],
        ]));
        rows = [];
      }
    } else if (tag == '</w:tc>' && inTable) {
      row.add(_decodeXmlEntities(cell.toString().trim()));
      cell.clear();
    } else if (tag == '</w:tr>' && inTable) {
      if (row.isNotEmpty) rows.add(row);
      row = [];
    } else if (tag == '</w:p>') {
      // In a table, a paragraph break stays inside the current cell.
      inTable ? cell.write(' ') : para.write('\n');
    }
  }
  flushPara();
  return blocks;
}

/// Opens a full-screen viewer for [a]. Images, PDFs, spreadsheets, Word docs
/// and text files render in the app; every other format (PowerPoint,
/// archives, …) shows a clear "no preview" fail-safe with a Download action,
/// so a tap never dead-ends or crashes. Available on Android/iOS/Web/Windows/
/// macOS/Linux.
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
      return _textPane(text, bytes);
    }

    if (_spreadsheetExtensions.contains(ext)) {
      try {
        final sheets = _parseSpreadsheet(bytes);
        if (sheets.isEmpty) {
          return _UnsupportedPane(attachment: attachment, bytes: bytes);
        }
        return _spreadsheetPane(sheets, bytes);
      } catch (_) {
        return _UnsupportedPane(attachment: attachment, bytes: bytes);
      }
    }

    if (ext == 'docx') {
      try {
        return _docxPane(_parseDocx(bytes), bytes);
      } catch (_) {
        return _UnsupportedPane(attachment: attachment, bytes: bytes);
      }
    }

    // Unsupported format — the fail-safe.
    return _UnsupportedPane(attachment: attachment, bytes: bytes);
  }

  Widget _textPane(String text, Uint8List bytes) {
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

  /// Word preview: paragraphs as flowing text, tables as bordered grids —
  /// mirroring the source document instead of flattening rows to lines.
  Widget _docxPane(List<_DocxBlock> blocks, Uint8List bytes) {
    return _WithDownloadBar(
      attachment: attachment,
      bytes: bytes,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: blocks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final block = blocks[i];
          if (block is _DocxTable) return GridTableView(rows: block.rows);
          return SelectableText(
            (block as _DocxParagraphs).text,
            style: const TextStyle(fontSize: 13.5, height: 1.5),
          );
        },
      ),
    );
  }

  /// Spreadsheet preview: one bordered grid per sheet (named when there is
  /// more than one), instead of a flattened tab-separated text dump.
  Widget _spreadsheetPane(List<_SheetTable> sheets, Uint8List bytes) {
    return _WithDownloadBar(
      attachment: attachment,
      bytes: bytes,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sheets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 22),
        itemBuilder: (context, i) {
          final sheet = sheets[i];
          if (sheets.length == 1) return GridTableView(rows: sheet.rows);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sheet.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              GridTableView(rows: sheet.rows),
            ],
          );
        },
      ),
    );
  }
}

/// Renders a parsed table (from a .docx or spreadsheet) as a bordered grid
/// with a highlighted header row. Scrolls horizontally when wider than the
/// screen.
class GridTableView extends StatelessWidget {
  final List<List<String>> rows;
  const GridTableView({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final borderColor = dark ? AppColors.navy700 : AppColors.slate200;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder.all(color: borderColor),
        children: [
          for (var r = 0; r < rows.length; r++)
            TableRow(
              decoration: r == 0
                  ? BoxDecoration(
                      color: scheme.primary.withValues(alpha: dark ? 0.2 : 0.08),
                    )
                  : null,
              children: [
                for (final cell in rows[r])
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    // Long cells (e.g. specifications) wrap instead of
                    // stretching their column across the whole table.
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: SelectableText(
                        cell,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight:
                              r == 0 ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
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
