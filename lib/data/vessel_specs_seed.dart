import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';

import '../models/attachment.dart';
import '../models/vessel_spec.dart';

/// Bumps whenever the bundled spec set changes, so a new set re-seeds once.
const _seedFlag = 'specsSeeded_v1';

/// The manufacturer specification PDF bundled for each vessel, mapped to the
/// vessel id it belongs to. Files live under assets/specs/ (declared in
/// pubspec.yaml).
const _seeds = <Map<String, String>>[
  {
    'vesselId': 'mrd-601',
    'asset': 'assets/specs/MARIDIVE 601.pdf',
    'file': 'MARIDIVE 601.pdf',
  },
  {
    'vesselId': 'mrd-704',
    'asset': 'assets/specs/704 R2.pdf',
    'file': '704 R2.pdf',
  },
  {
    'vesselId': 'mrd-zohr-1',
    'asset': 'assets/specs/Maridive ZOHR I.pdf',
    'file': 'Maridive ZOHR I.pdf',
  },
  {
    'vesselId': 'mrd-zohr-2',
    'asset': 'assets/specs/Maridive ZOHR II.pdf',
    'file': 'Maridive ZOHR II.pdf',
  },
  {
    'vesselId': 'mrd-701',
    'asset': 'assets/specs/Maridive 701-702-703 - 704.pdf',
    'file': 'Maridive 701-702-703 - 704.pdf',
  },
];

/// Loads the bundled specification PDFs into the specs box once, so every
/// vessel ships with its manufacturer spec sheet already in its
/// Specifications library. Guarded by a flag in [settingsBox] so it runs a
/// single time and never resurrects a spec the user has deleted.
Future<void> seedVesselSpecs({
  required Box specsBox,
  required Box settingsBox,
}) async {
  if (settingsBox.get(_seedFlag) == true) return;
  for (final s in _seeds) {
    try {
      final data = await rootBundle.load(s['asset']!);
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final spec = VesselSpec(
        id: '${s['vesselId']}_seed_spec',
        vesselId: s['vesselId']!,
        title: 'Vessel Specification',
        notes: 'Manufacturer specification sheet.',
        attachments: [
          Attachment(name: s['file']!, dataBase64: base64Encode(bytes)),
        ],
        createdAt: DateTime.now(),
      );
      await specsBox.put(spec.id, spec.toMap());
    } catch (_) {
      // A missing/unreadable asset shouldn't block app start; skip it.
    }
  }
  await settingsBox.put(_seedFlag, true);
}
