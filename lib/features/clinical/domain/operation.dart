import 'package:freezed_annotation/freezed_annotation.dart';

part 'operation.freezed.dart';
part 'operation.g.dart';

/// A surgical operation prescribed within a visit (mirrors backend `OperationOut`).
@freezed
abstract class Operation with _$Operation {
  const Operation._();

  const factory Operation({
    required String id,
    required String visitId,
    required String patientId,
    String? doctorId,
    required String operationTypeId,
    required String typeName,
    required String eye,
    required String status,
    String? scheduledAt,
    String? performedAt,
    String? notes,
    required String createdAt,
  }) = _Operation;

  factory Operation.fromJson(Map<String, dynamic> json) =>
      _$OperationFromJson(json);

  bool get isPlanned => status == 'planned';

  String get eyeLabel => switch (eye) {
        'od' => 'правый глаз',
        'os' => 'левый глаз',
        'ou' => 'оба глаза',
        _ => eye,
      };

  String get statusLabel => switch (status) {
        'planned' => 'запланирована',
        'done' => 'выполнена',
        'cancelled' => 'отменена',
        _ => status,
      };
}
