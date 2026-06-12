import 'package:freezed_annotation/freezed_annotation.dart';

part 'visit_summary.freezed.dart';
part 'visit_summary.g.dart';

/// Lightweight projection of a visit for pickers/lists (subset of `VisitOut`).
@freezed
abstract class VisitSummary with _$VisitSummary {
  const VisitSummary._();

  const factory VisitSummary({
    required String id,
    required String visitNo,
    required String status,
    required String openedAt,
  }) = _VisitSummary;

  factory VisitSummary.fromJson(Map<String, dynamic> json) => _$VisitSummaryFromJson(json);

  String get statusLabel => switch (status) {
        'completed' => 'закрыт',
        'cancelled' => 'отменён',
        'in_progress' => 'в работе',
        _ => status,
      };

  /// Closed/cancelled visits must be distinguishable in the picker — the
  /// backend rejects prescribing on them with 409.
  String get label =>
      '$visitNo · ${openedAt.split('T').first}'
      '${status == 'open' ? '' : ' · $statusLabel'}';
}
