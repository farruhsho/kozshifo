import 'package:freezed_annotation/freezed_annotation.dart';

part 'operation_type.freezed.dart';
part 'operation_type.g.dart';

/// Catalog entry of a surgical operation (mirrors backend `OperationTypeOut`).
/// `price` is a decimal string — money never becomes a double on the client.
@freezed
abstract class OperationType with _$OperationType {
  const factory OperationType({
    required String id,
    required String code,
    required String name,
    required String serviceId,
    required String price,
    int? durationMinutes,
    @Default(true) bool isActive,
    String? description,
    @Default(<OperationConsumable>[]) List<OperationConsumable> consumables,
  }) = _OperationType;

  factory OperationType.fromJson(Map<String, dynamic> json) =>
      _$OperationTypeFromJson(json);
}

/// One consumable auto-written-off when the operation is performed.
/// `quantity` is a decimal string (e.g. "1.000").
@freezed
abstract class OperationConsumable with _$OperationConsumable {
  const factory OperationConsumable({
    required String productId,
    required String productName,
    required String quantity,
  }) = _OperationConsumable;

  factory OperationConsumable.fromJson(Map<String, dynamic> json) =>
      _$OperationConsumableFromJson(json);
}
