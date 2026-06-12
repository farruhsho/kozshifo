import 'package:freezed_annotation/freezed_annotation.dart';

part 'service.freezed.dart';
part 'service.g.dart';

/// Priced catalog service (mirrors backend `ServiceOut`). Price is a decimal
/// string — display-only on the client; billing math stays on the server.
@freezed
abstract class Service with _$Service {
  const factory Service({
    required String id,
    required String code,
    required String name,
    required String price,
    int? durationMinutes,
    String? description,
    @Default(true) bool isActive,
    String? categoryId,
  }) = _Service;

  factory Service.fromJson(Map<String, dynamic> json) => _$ServiceFromJson(json);
}

/// Display-only cart pre-total: sums decimal-string prices × qty.
/// The authoritative total always comes back from the server with the visit.
double cartTotalValue(Iterable<(String price, int qty)> lines) {
  var total = 0.0;
  for (final (price, qty) in lines) {
    total += (double.tryParse(price) ?? 0) * qty;
  }
  return total;
}
