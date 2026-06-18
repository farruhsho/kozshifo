/// A diagnosis the current user (e.g. a diagnostician) is allowed to record as a
/// conclusion (заключение). Mirrors the backend's allowed-diagnoses payload from
/// `GET /diagnoses/mine`. Plain model (no codegen).
class Diagnosis {
  const Diagnosis({
    required this.id,
    required this.name,
    this.code,
    this.category,
    this.icd10,
  });

  final String id;
  final String name;
  final String? code;
  final String? category;
  final String? icd10;

  factory Diagnosis.fromJson(Map<String, dynamic> json) => Diagnosis(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        code: json['code'] as String?,
        category: json['category'] as String?,
        icd10: json['icd10'] as String?,
      );

  /// Human-readable label for the dropdown — prefixes the category when present.
  String get label => category != null ? '$category · $name' : name;
}
