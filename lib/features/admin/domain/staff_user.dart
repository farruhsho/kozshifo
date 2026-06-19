import 'package:freezed_annotation/freezed_annotation.dart';

part 'staff_user.freezed.dart';
part 'staff_user.g.dart';

/// Staff member as managed by the owner (mirrors backend `UserOut`).
///
/// The backend sends `roles` as a list of `{id, name}` refs (`RoleRef`);
/// for the admin UI only the names matter, so the converter keeps just those.
@freezed
abstract class StaffUser with _$StaffUser {
  const factory StaffUser({
    required String id,
    required String email,
    required String fullName,
    String? phone,
    @Default(true) bool isActive,
    @Default(false) bool isSuperuser,
    String? branchId,
    // Процентная оплата врача (доля от выручки его визитов). Decimal приходит
    // строкой (например "12.50"); null = не на процентной оплате.
    String? salaryPercent,
    // Кабинет врача (например «Каб. 1») — при вызове талона в очереди пациент
    // направляется именно сюда. Задаёт директор. null = не клинический сотрудник.
    String? cabinet,
    // Префикс талона очереди (например «С» → С-001). null = авто из имени.
    String? queuePrefix,
    // Внешний (приезжий) хирург — например, оперирует наездами из Ташкента.
    @Default(false) bool isExternalSurgeon,
    @JsonKey(fromJson: roleNamesFromJson)
    @Default(<String>[])
    List<String> roles,
    // Услуги, которые ведёт врач (бэкенд UserOut.services: [{id, code, name}]).
    @JsonKey(fromJson: doctorServicesFromJson, toJson: doctorServicesToJson)
    @Default(<DoctorService>[])
    List<DoctorService> services,
    // Диагнозы/заключения, которые сотрудник вправе фиксировать
    // (бэкенд UserOut.diagnoses: [{id, code, name}]).
    @JsonKey(fromJson: doctorDiagnosesFromJson, toJson: doctorDiagnosesToJson)
    @Default(<DoctorDiagnosis>[])
    List<DoctorDiagnosis> diagnoses,
  }) = _StaffUser;

  factory StaffUser.fromJson(Map<String, dynamic> json) =>
      _$StaffUserFromJson(json);
}

/// Backend emits `roles: [{id, name}, …]`; our own `toJson` emits plain
/// strings. Accept both shapes so round-trips stay lossless.
List<String> roleNamesFromJson(Object? raw) => [
  for (final e in (raw as List<dynamic>? ?? const []))
    if (e is Map) e['name'] as String else e as String,
];

/// One service a doctor provides (subset of backend `ServiceRef`).
typedef DoctorService = ({String id, String code, String name});

/// Backend emits `services: [{id, code, name}, …]` on UserOut.
List<DoctorService> doctorServicesFromJson(Object? raw) => [
  for (final e in (raw as List<dynamic>? ?? const []))
    (
      id: (e as Map<String, dynamic>)['id'] as String,
      code: e['code'] as String,
      name: e['name'] as String,
    ),
];

List<Map<String, String>> doctorServicesToJson(List<DoctorService> v) => [
  for (final s in v) {'id': s.id, 'code': s.code, 'name': s.name},
];

/// One diagnosis/conclusion a staff member may record (subset of backend
/// `DiagnosisRef`).
typedef DoctorDiagnosis = ({String id, String code, String name});

/// Backend emits `diagnoses: [{id, code, name}, …]` on UserOut.
List<DoctorDiagnosis> doctorDiagnosesFromJson(Object? raw) => [
  for (final e in (raw as List<dynamic>? ?? const []))
    (
      id: (e as Map<String, dynamic>)['id'] as String,
      code: e['code'] as String,
      name: e['name'] as String,
    ),
];

List<Map<String, String>> doctorDiagnosesToJson(List<DoctorDiagnosis> v) => [
  for (final d in v) {'id': d.id, 'code': d.code, 'name': d.name},
];
