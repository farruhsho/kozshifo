import 'package:freezed_annotation/freezed_annotation.dart';

part 'exam_template.freezed.dart';
part 'exam_template.g.dart';

/// A doctor's saved exam-conclusion template (mirrors backend `ExamTemplateOut`).
/// Picking one fills diagnosis / ICD-10 / recommendations instead of retyping.
@freezed
abstract class ExamTemplate with _$ExamTemplate {
  const factory ExamTemplate({
    required String id,
    required String doctorId,
    required String name,
    String? diagnosis,
    String? icd10,
    String? recommendations,
    String? createdAt,
  }) = _ExamTemplate;

  factory ExamTemplate.fromJson(Map<String, dynamic> json) =>
      _$ExamTemplateFromJson(json);
}
