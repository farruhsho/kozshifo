import 'package:freezed_annotation/freezed_annotation.dart';

part 'hanging_visit.freezed.dart';
part 'hanging_visit.g.dart';

/// Один зависший визит внутри категории (mirrors backend `HangingVisitRow`).
@freezed
abstract class HangingVisitRow with _$HangingVisitRow {
  const factory HangingVisitRow({
    required String visitId,
    required String visitNo,
    required String patientId,
    required String patientName,
    required String flowStatus,
    required String openedAt,
    required String detail,
  }) = _HangingVisitRow;

  factory HangingVisitRow.fromJson(Map<String, dynamic> json) =>
      _$HangingVisitRowFromJson(json);
}

/// Категория зависших визитов с конкретными пациентами (mirrors backend
/// `HangingCategory`). [count] — всего найдено; [visits] может быть усечён.
@freezed
abstract class HangingCategory with _$HangingCategory {
  const HangingCategory._();

  const factory HangingCategory({
    required String category,
    required String label,
    required String severity, // info | warning | critical
    required int count,
    String? route,
    @Default(<HangingVisitRow>[]) List<HangingVisitRow> visits,
  }) = _HangingCategory;

  factory HangingCategory.fromJson(Map<String, dynamic> json) =>
      _$HangingCategoryFromJson(json);

  bool get isCritical => severity == 'critical';
  bool get isInfo => severity == 'info';
}
