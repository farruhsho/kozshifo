import 'package:freezed_annotation/freezed_annotation.dart';

part 'patient.freezed.dart';
part 'patient.g.dart';

/// Patient master record (mirrors `PatientOut`).
@freezed
abstract class Patient with _$Patient {
  const Patient._();

  const factory Patient({
    required String id,
    required String mrn,
    required String firstName,
    required String lastName,
    String? middleName,
    required String fullName,
    String? birthDate,
    String? gender,
    String? phone,
    String? email,
    String? address,
    String? notes,
    String? branchId,
  }) = _Patient;

  factory Patient.fromJson(Map<String, dynamic> json) => _$PatientFromJson(json);

  String get initials {
    final a = lastName.isNotEmpty ? lastName[0] : '';
    final b = firstName.isNotEmpty ? firstName[0] : '';
    return '$a$b'.toUpperCase();
  }
}
