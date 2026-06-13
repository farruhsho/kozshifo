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
    @JsonKey(fromJson: roleNamesFromJson)
    @Default(<String>[])
    List<String> roles,
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
