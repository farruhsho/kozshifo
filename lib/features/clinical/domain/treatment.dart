import 'package:freezed_annotation/freezed_annotation.dart';

part 'treatment.freezed.dart';
part 'treatment.g.dart';

/// A treatment prescription — procedure or medication — within a visit
/// (mirrors backend `TreatmentOut`). `quantity` is a decimal string.
@freezed
abstract class Treatment with _$Treatment {
  const Treatment._();

  const factory Treatment({
    required String id,
    required String visitId,
    required String patientId,
    String? doctorId,
    required String kind,
    required String name,
    String? productId,
    String? quantity,
    String? instructions,
    required String status,
    String? performedAt,
    required String createdAt,
    @Default(1) int sessionsTotal,
    @Default(0) int sessionsDone,
  }) = _Treatment;

  factory Treatment.fromJson(Map<String, dynamic> json) =>
      _$TreatmentFromJson(json);

  bool get isPrescribed => status == 'prescribed';
  bool get isMedication => kind == 'medication';

  /// Многодневный курс (более одного сеанса).
  bool get isCourse => sessionsTotal > 1;

  /// Прогресс курса «X/N».
  String get sessionProgress => '$sessionsDone/$sessionsTotal';

  String get kindLabel => switch (kind) {
        'procedure' => 'Процедура',
        'medication' => 'Медикамент',
        _ => kind,
      };

  /// The backend's terminal status is always `done`; for a medication that
  /// means «выдано» (dispensed), for a procedure «выполнено».
  String get statusLabel => switch (status) {
        'prescribed' => 'назначено',
        'done' => isMedication ? 'выдано' : 'выполнено',
        'cancelled' => 'отменено',
        _ => status,
      };
}
