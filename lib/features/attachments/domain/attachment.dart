/// A patient document attachment (УЗИ-заключение, анализ на ВИЧ, прочие сканы).
/// Mirrors the backend `AttachmentOut`. Bytes are fetched separately via
/// `GET /attachments/{id}/file`.
class Attachment {
  const Attachment({
    required this.id,
    required this.patientId,
    required this.kind,
    required this.createdAt,
    this.visitId,
    this.operationId,
    this.originalName,
    this.contentType,
    this.size,
    this.note,
    this.uploadedById,
    this.uploadedByName,
  });

  final String id;
  final String patientId;
  final String kind; // uzi | hiv | lab | other
  final String createdAt;
  final String? visitId;
  final String? operationId;
  final String? originalName;
  final String? contentType;
  final int? size;
  final String? note;
  final String? uploadedById;
  final String? uploadedByName;

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        kind: json['kind'] as String? ?? 'other',
        createdAt: json['created_at'] as String? ?? '',
        visitId: json['visit_id'] as String?,
        operationId: json['operation_id'] as String?,
        originalName: json['original_name'] as String?,
        contentType: json['content_type'] as String?,
        size: (json['size'] as num?)?.toInt(),
        note: json['note'] as String?,
        uploadedById: json['uploaded_by_id'] as String?,
        uploadedByName: json['uploaded_by_name'] as String?,
      );

  static const kindLabels = <String, String>{
    'uzi': 'УЗИ',
    'hiv': 'Анализ на ВИЧ',
    'lab': 'Лаборатория',
    'other': 'Документ',
  };

  String get kindLabel => kindLabels[kind] ?? 'Документ';

  String get displayName =>
      (originalName != null && originalName!.trim().isNotEmpty)
          ? originalName!
          : '$kindLabel.pdf';

  String get dateLabel =>
      createdAt.isEmpty ? '' : createdAt.replaceFirst('T', ' ').split('.').first;
}
