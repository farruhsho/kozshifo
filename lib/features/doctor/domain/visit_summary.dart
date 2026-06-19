import 'package:freezed_annotation/freezed_annotation.dart';

part 'visit_summary.freezed.dart';
part 'visit_summary.g.dart';

/// Projection of a visit for the card's picker AND the visit-history panel.
///
/// All fields come from the one `/visits?patient_id=` payload (full `VisitOut`),
/// so the history list needs no extra request. The picker only reads
/// [visitNo]/[openedAt]/[status]/[flowStatus]; the money/[items] fields are
/// optional (defaulted) so older/partial payloads and the const test fixtures
/// keep parsing.
@freezed
abstract class VisitSummary with _$VisitSummary {
  const VisitSummary._();

  const factory VisitSummary({
    required String id,
    required String visitNo,
    required String status,
    @Default('registered') String flowStatus,
    required String openedAt,
    String? branchId,
    // ── Enrichment for the «История визитов» panel ──────────────────────────
    @Default('consultation') String visitType,
    String? closedAt,
    // Money is a decimal string on the client (e.g. "150000.00"); never float.
    @Default('0') String totalAmount,
    @Default('0') String paidAmount,
    @Default('0') String discountValue,
    @Default('0') String payable,
    @Default('0') String balance,
    String? discountReason,
    @Default(0) int priority,
    @Default(<VisitItemSummary>[]) List<VisitItemSummary> items,
    // ── Clinical context («История посещений»): врач/кабинет/диагнозы/лечение ──
    String? doctorName,
    String? doctorCabinet,
    @Default(<String>[]) List<String> diagnoses,
    @Default(<String>[]) List<String> treatments,
  }) = _VisitSummary;

  factory VisitSummary.fromJson(Map<String, dynamic> json) => _$VisitSummaryFromJson(json);

  String get statusLabel => switch (status) {
        'open' => 'открыт',
        'completed' => 'закрыт',
        'cancelled' => 'отменён',
        'in_progress' => 'в работе',
        _ => status,
      };

  /// Дата визита `dd.MM.yyyy` из ISO `opened_at` (без времени).
  String get openedDate {
    final d = DateTime.tryParse(openedAt)?.toLocal();
    if (d == null) return openedAt.split('T').first;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  /// Время визита `HH:mm` из ISO `opened_at` (локальное).
  String get openedTime {
    final d = DateTime.tryParse(openedAt)?.toLocal();
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}';
  }

  /// Дата + время для шапки строки истории (`dd.MM.yyyy · HH:mm`).
  String get openedDateTime =>
      openedTime.isEmpty ? openedDate : '$openedDate · $openedTime';

  /// Closed/cancelled visits must be distinguishable in the picker — the
  /// backend rejects prescribing on them with 409.
  String get label =>
      '$visitNo · ${openedAt.split('T').first}'
      '${status == 'open' ? '' : ' · $statusLabel'}';

  /// Emergency intake (reception «ЭКСТРЕННО») — priority weight > 0.
  bool get isEmergency => priority > 0;

  /// Still owes money (balance > 0); tolerate float noise on the parsed string.
  bool get hasDebt => (double.tryParse(balance) ?? 0) > 0.005;

  /// A reception discount was applied to this visit.
  bool get hasDiscount => (double.tryParse(discountValue) ?? 0) > 0.005;
}

/// One billed line of a visit (subset of backend `VisitItemOut`) — service name,
/// quantity and the line total, for the visit-history breakdown.
@freezed
abstract class VisitItemSummary with _$VisitItemSummary {
  const factory VisitItemSummary({
    required String serviceName,
    @Default(1) int quantity,
    @Default('0') String total,
  }) = _VisitItemSummary;

  factory VisitItemSummary.fromJson(Map<String, dynamic> json) => _$VisitItemSummaryFromJson(json);
}
