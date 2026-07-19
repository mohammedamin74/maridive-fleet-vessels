import '../models/attachment.dart';

/// One uploaded file inside an [IngestionBatch], from upload through routing
/// and extraction. Session-local (never written to the cloud directly) —
/// only what it produces, an accepted [ModuleItem], gets persisted, through
/// the same provider path a manual entry would use.
enum FileStatus { uploaded, extracting, routed, error }

class BatchFile {
  final String id;
  final String batchId;
  final Attachment attachment;
  final String contentHash;
  final int sizeBytes;
  final String detectedExt;
  final FileStatus status;
  final DateTime uploadedAt;

  const BatchFile({
    required this.id,
    required this.batchId,
    required this.attachment,
    required this.contentHash,
    required this.sizeBytes,
    required this.detectedExt,
    required this.status,
    required this.uploadedAt,
  });

  BatchFile copyWith({FileStatus? status}) => BatchFile(
        id: id,
        batchId: batchId,
        attachment: attachment,
        contentHash: contentHash,
        sizeBytes: sizeBytes,
        detectedExt: detectedExt,
        status: status ?? this.status,
        uploadedAt: uploadedAt,
      );
}
