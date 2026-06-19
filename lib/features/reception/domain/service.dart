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
    @Default(false) bool isDiagnostic,
    String? categoryId,
    // Врачи, которым разрешена услуга (бэкенд ServiceOut.doctors:
    // [{id, full_name, cabinet}]). Кабинет приёма берётся от врача.
    @JsonKey(fromJson: serviceDoctorsFromJson, toJson: serviceDoctorsToJson)
    @Default(<ServiceDoctor>[])
    List<ServiceDoctor> doctors,
  }) = _Service;

  factory Service.fromJson(Map<String, dynamic> json) =>
      _$ServiceFromJson(json);
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

/// A doctor eligible to provide a service (subset of backend `DoctorRef`).
typedef ServiceDoctor = ({String id, String fullName, String? cabinet});

/// Backend emits `doctors: [{id, full_name, cabinet}, …]` on ServiceOut.
List<ServiceDoctor> serviceDoctorsFromJson(Object? raw) => [
  for (final e in (raw as List<dynamic>? ?? const []))
    (
      id: (e as Map<String, dynamic>)['id'] as String,
      fullName: e['full_name'] as String,
      cabinet: e['cabinet'] as String?,
    ),
];

List<Map<String, String?>> serviceDoctorsToJson(List<ServiceDoctor> v) => [
  for (final d in v)
    {'id': d.id, 'full_name': d.fullName, 'cabinet': d.cabinet},
];
