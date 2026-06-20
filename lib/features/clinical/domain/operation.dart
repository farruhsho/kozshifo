import 'package:freezed_annotation/freezed_annotation.dart';

part 'operation.freezed.dart';
part 'operation.g.dart';

/// A surgical operation in the TZ Modul 6 lifecycle (mirrors backend
/// `OperationOut`): doctor refers → reception schedules (date/surgeon/price,
/// bills the visit) → in progress → performed → completed.
@freezed
abstract class Operation with _$Operation {
  const Operation._();

  const factory Operation({
    required String id,
    required String visitId,
    required String patientId,
    required String patientName,
    String? referringDoctorId,
    String? referringDoctorName,
    String? surgeonId,
    String? surgeonName,
    required String operationTypeId,
    required String typeName,
    required String eye,
    @Default('normal') String priority,
    required String status,
    String? price,
    String? scheduledAt,
    String? performedAt,
    String? completedAt,
    String? notes,
    String? result,
    String? financiallyClosedAt,
    required String createdAt,
  }) = _Operation;

  factory Operation.fromJson(Map<String, dynamic> json) =>
      _$OperationFromJson(json);

  /// Awaiting reception scheduling (no date/price/surgeon yet).
  bool get isReferred => status == 'referred';

  /// Scheduled — billed, has a date/surgeon; can be started/performed.
  bool get isScheduled => status == 'scheduled';

  bool get isInProgress => status == 'in_progress';
  bool get isPerformed => status == 'performed';

  /// Финансово закрыта: цена/счёт заморожены, изменить стоимость нельзя.
  bool get isFinanciallyClosed => financiallyClosedAt != null;

  /// Not yet performed → still cancellable / re-schedulable.
  bool get isOpen =>
      status == 'referred' || status == 'scheduled' || status == 'in_progress';

  bool get isUrgent => priority == 'urgent';

  String get eyeLabel => switch (eye) {
    'od' => 'правый глаз',
    'os' => 'левый глаз',
    'ou' => 'оба глаза',
    _ => eye,
  };

  String get statusLabel => switch (status) {
    'referred' => 'направлен',
    'scheduled' => 'запланирована',
    'in_progress' => 'идёт',
    'performed' => 'выполнена',
    'completed' => 'завершена',
    'cancelled' => 'отменена',
    _ => status,
  };

  /// `scheduledAt` как ЛОКАЛЬНОЕ время. Бэкенд хранит UTC; Postgres отдаёт его
  /// со смещением, а SQLite (dev/fallback) — НАИВНО (без Z), из-за чего
  /// `DateTime.parse(...).toLocal()` ничего не делал бы и смещал бы день. Здесь
  /// наивную строку трактуем как UTC, поэтому день/время одинаковы на обеих БД.
  DateTime? get scheduledAtLocal {
    final s = scheduledAt;
    if (s == null) return null;
    final raw = DateTime.parse(s);
    final utc = raw.isUtc
        ? raw
        : DateTime.utc(
            raw.year,
            raw.month,
            raw.day,
            raw.hour,
            raw.minute,
            raw.second,
          );
    return utc.toLocal();
  }
}
