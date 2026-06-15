import 'package:freezed_annotation/freezed_annotation.dart';

part 'enrollment.freezed.dart';
part 'enrollment.g.dart';

/// A staff member's Face ID enrollment status (mirrors backend `EnrollmentRow`).
@freezed
abstract class EnrollmentRow with _$EnrollmentRow {
  const factory EnrollmentRow({
    required String userId,
    required String fullName,
    required String email,
    String? branchId,
    String? faceidEmployeeNo,
    required bool enrolled,
  }) = _EnrollmentRow;

  factory EnrollmentRow.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentRowFromJson(json);
}

/// Outcome of an enroll / face-upload / remove call (mirrors `EnrollResult`).
/// [pushedToDevice] is false when the terminal was offline — the local mapping
/// is still saved, so re-running enroll retries the push.
@freezed
abstract class EnrollResult with _$EnrollResult {
  const factory EnrollResult({
    required String userId,
    required String faceidEmployeeNo,
    required bool pushedToDevice,
    @Default(false) bool faceUploaded,
    String? error,
  }) = _EnrollResult;

  factory EnrollResult.fromJson(Map<String, dynamic> json) =>
      _$EnrollResultFromJson(json);
}
