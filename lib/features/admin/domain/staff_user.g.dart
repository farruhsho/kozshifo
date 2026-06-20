// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StaffUser _$StaffUserFromJson(Map<String, dynamic> json) => _StaffUser(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['full_name'] as String,
  phone: json['phone'] as String?,
  isActive: json['is_active'] as bool? ?? true,
  isSuperuser: json['is_superuser'] as bool? ?? false,
  branchId: json['branch_id'] as String?,
  salaryPercent: json['salary_percent'] as String?,
  consultSalaryType: json['consult_salary_type'] as String?,
  consultSalaryValue: json['consult_salary_value'] as String?,
  operationSalaryType: json['operation_salary_type'] as String?,
  operationSalaryValue: json['operation_salary_value'] as String?,
  cabinet: json['cabinet'] as String?,
  queuePrefix: json['queue_prefix'] as String?,
  isExternalSurgeon: json['is_external_surgeon'] as bool? ?? false,
  roles: json['roles'] == null
      ? const <String>[]
      : roleNamesFromJson(json['roles']),
  services: json['services'] == null
      ? const <DoctorService>[]
      : doctorServicesFromJson(json['services']),
  diagnoses: json['diagnoses'] == null
      ? const <DoctorDiagnosis>[]
      : doctorDiagnosesFromJson(json['diagnoses']),
);

Map<String, dynamic> _$StaffUserToJson(_StaffUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.fullName,
      'phone': instance.phone,
      'is_active': instance.isActive,
      'is_superuser': instance.isSuperuser,
      'branch_id': instance.branchId,
      'salary_percent': instance.salaryPercent,
      'consult_salary_type': instance.consultSalaryType,
      'consult_salary_value': instance.consultSalaryValue,
      'operation_salary_type': instance.operationSalaryType,
      'operation_salary_value': instance.operationSalaryValue,
      'cabinet': instance.cabinet,
      'queue_prefix': instance.queuePrefix,
      'is_external_surgeon': instance.isExternalSurgeon,
      'roles': instance.roles,
      'services': doctorServicesToJson(instance.services),
      'diagnoses': doctorDiagnosesToJson(instance.diagnoses),
    };
