import 'package:freezed_annotation/freezed_annotation.dart';

part 'frequent_diagnosis.freezed.dart';
part 'frequent_diagnosis.g.dart';

/// One of the doctor's most-used diagnoses (mirrors `FrequentDiagnosis`).
@freezed
abstract class FrequentDiagnosis with _$FrequentDiagnosis {
  const factory FrequentDiagnosis({
    required String diagnosis,
    required int count,
  }) = _FrequentDiagnosis;

  factory FrequentDiagnosis.fromJson(Map<String, dynamic> json) =>
      _$FrequentDiagnosisFromJson(json);
}
