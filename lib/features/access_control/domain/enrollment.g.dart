// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enrollment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EnrollmentRow _$EnrollmentRowFromJson(Map<String, dynamic> json) =>
    _EnrollmentRow(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      branchId: json['branch_id'] as String?,
      faceidEmployeeNo: json['faceid_employee_no'] as String?,
      enrolled: json['enrolled'] as bool,
    );

Map<String, dynamic> _$EnrollmentRowToJson(_EnrollmentRow instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'full_name': instance.fullName,
      'email': instance.email,
      'branch_id': instance.branchId,
      'faceid_employee_no': instance.faceidEmployeeNo,
      'enrolled': instance.enrolled,
    };

_EnrollResult _$EnrollResultFromJson(Map<String, dynamic> json) =>
    _EnrollResult(
      userId: json['user_id'] as String,
      faceidEmployeeNo: json['faceid_employee_no'] as String,
      pushedToDevice: json['pushed_to_device'] as bool,
      faceUploaded: json['face_uploaded'] as bool? ?? false,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$EnrollResultToJson(_EnrollResult instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'faceid_employee_no': instance.faceidEmployeeNo,
      'pushed_to_device': instance.pushedToDevice,
      'face_uploaded': instance.faceUploaded,
      'error': instance.error,
    };
