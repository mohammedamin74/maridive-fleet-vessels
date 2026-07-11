/// A single uploaded file of any format (image, PDF, Word, etc.).
///
/// Unlike the earlier image-only "photo" storage — which kept a bare
/// base64 string with no filename — an [Attachment] carries the original
/// filename (and thus its extension) alongside the base64-encoded bytes,
/// so non-image documents can be labelled and identified in the UI and in
/// exported reports.
class Attachment {
  final String name; // original filename incl. extension, e.g. "cert.pdf"
  final String dataBase64; // inline bytes; '' when the file lives in Storage
  final String? storagePath; // Supabase Storage object path; null when inline

  const Attachment({
    required this.name,
    this.dataBase64 = '',
    this.storagePath,
  });

  /// True when the bytes live in shared Supabase Storage (the record keeps only
  /// this small path) rather than being base64-inlined in the record itself.
  bool get isCloud => storagePath != null && storagePath!.isNotEmpty;

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
  }

  bool get isImage => const {
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
        'bmp',
        'heic',
        'heif',
      }.contains(extension);

  Map<String, dynamic> toMap() => {
        'name': name,
        'data': dataBase64,
        if (storagePath != null && storagePath!.isNotEmpty) 'path': storagePath,
      };

  factory Attachment.fromMap(Map<dynamic, dynamic> map) => Attachment(
        name: (map['name'] as String?) ?? 'file',
        dataBase64: (map['data'] as String?) ?? '',
        storagePath: map['path'] as String?,
      );

  /// Reads an attachment list from a stored record map, tolerating both the
  /// current format (`attachments`: list of {name, data} maps) and the legacy
  /// format (`photosBase64`: list of bare base64 image strings), so records
  /// saved before file-upload support still load and display.
  static List<Attachment> listFromMap(Map<dynamic, dynamic> map) {
    final modern = map['attachments'];
    if (modern is List) {
      return modern
          .map((e) => Attachment.fromMap(e as Map))
          .toList(growable: false);
    }
    final legacy = map['photosBase64'];
    if (legacy is List) {
      var i = 0;
      return legacy.map((e) {
        i++;
        return Attachment(name: 'Photo_$i.jpg', dataBase64: e as String);
      }).toList(growable: false);
    }
    return const [];
  }

  static List<Map<String, dynamic>> listToMap(List<Attachment> attachments) =>
      attachments.map((a) => a.toMap()).toList();
}
