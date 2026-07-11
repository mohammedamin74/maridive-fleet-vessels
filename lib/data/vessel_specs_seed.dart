/// The manufacturer specification PDF bundled for each vessel. Files live under
/// assets/specs/ (declared in pubspec.yaml) and are uploaded once to shared
/// Supabase Storage by [VesselSpecProvider] so every device sees the same
/// document library. Deterministic ids/paths keep the seed idempotent.
class VesselSpecSeed {
  final String vesselId;
  final String asset; // bundled asset path
  final String file; // display filename

  const VesselSpecSeed({
    required this.vesselId,
    required this.asset,
    required this.file,
  });

  String get specId => '${vesselId}_seed_spec';
  String get storagePath => 'specs/$vesselId.pdf';
}

const List<VesselSpecSeed> vesselSpecSeeds = [
  VesselSpecSeed(
    vesselId: 'mrd-601',
    asset: 'assets/specs/MARIDIVE 601.pdf',
    file: 'MARIDIVE 601.pdf',
  ),
  VesselSpecSeed(
    vesselId: 'mrd-704',
    asset: 'assets/specs/704 R2.pdf',
    file: '704 R2.pdf',
  ),
  VesselSpecSeed(
    vesselId: 'mrd-zohr-1',
    asset: 'assets/specs/Maridive ZOHR I.pdf',
    file: 'Maridive ZOHR I.pdf',
  ),
  VesselSpecSeed(
    vesselId: 'mrd-zohr-2',
    asset: 'assets/specs/Maridive ZOHR II.pdf',
    file: 'Maridive ZOHR II.pdf',
  ),
  VesselSpecSeed(
    vesselId: 'mrd-701',
    asset: 'assets/specs/Maridive 701-702-703 - 704.pdf',
    file: 'Maridive 701-702-703 - 704.pdf',
  ),
];
