import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';

/// Opens the platform file picker restricted to images and returns the
/// picked file's bytes base64-encoded, or null if cancelled/unavailable.
/// Works uniformly across Android/iOS/Web/Windows/macOS/Linux since it
/// always reads bytes rather than relying on a filesystem path (which
/// isn't available on web).
Future<String?> pickImageAsBase64() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );
  final bytes = result?.files.single.bytes;
  if (bytes == null) return null;
  return base64Encode(bytes);
}

/// A horizontal strip of photo thumbnails (decoded from base64) with a
/// "remove" affordance on each, plus an "add photo" tile. Used for both
/// crew certificate avatars and daily-task completion evidence photos.
class PhotoPickerStrip extends StatelessWidget {
  final List<String> photosBase64;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;
  final bool multiple;

  const PhotoPickerStrip({
    super.key,
    required this.photosBase64,
    required this.onAdd,
    required this.onRemove,
    this.multiple = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final showAddTile = multiple || photosBase64.isEmpty;

    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < photosBase64.length; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(photosBase64[i]),
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: InkWell(
                      onTap: () => onRemove(i),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.statusMaintenance,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (showAddTile)
            InkWell(
              onTap: () async {
                final encoded = await pickImageAsBase64();
                if (encoded != null) onAdd(encoded);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: scheme.brightness == Brightness.dark
                      ? AppColors.navy700
                      : AppColors.slate100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: scheme.brightness == Brightness.dark
                        ? AppColors.navy600
                        : AppColors.slate200,
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                        size: 22),
                    const SizedBox(height: 4),
                    Text(t.addPhoto, style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
