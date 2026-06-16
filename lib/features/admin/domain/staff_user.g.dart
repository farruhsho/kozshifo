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
  cabinet: json['cabinet'] as String?,
  roles: json['roles'] == null
      ? const <String>[]
      : roleNamesFromJson(json['roles']),
  services: json['services'] == null
      ? const <DoctorService>[]
      : doctorServicesFromJson(json['services']),
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
      'cabinet': instance.cabinet,
      'roles': instance.roles,
      'services': doctorServicesToJson(instance.services),
    };
