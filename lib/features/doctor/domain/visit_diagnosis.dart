import 'package:freezed_annotation/freezed_annotation.dart';

part 'visit_diagnosis.freezed.dart';
part 'visit_diagnosis.g.dart';

/// One diagnosis line on a visit (TZ §7.1.5 — a visit accumulates many).
/// Mirrors backend `VisitDiagnosisOut`; JSON is snake_case (build.yaml).
@freezed
abstract class VisitDiagnosis with _$VisitDiagnosis {
  const factory VisitDiagnosis({
    required String id,
    required String visitId,
    required String patientId,
    String? doctorId,
    required String diagnosis,
    String? icd10,
    String? createdAt,
  }) = _VisitDiagnosis;

  factory VisitDiagnosis.fromJson(Map<String, dynamic> json) =>
      _$VisitDiagnosisFromJson(json);
}
