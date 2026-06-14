// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Appointment _$AppointmentFromJson(Map<String, dynamic> json) => _Appointment(
  id: json['id'] as String,
  appointmentNo: json['appointment_no'] as String,
  branchId: json['branch_id'] as String,
  patientId: json['patient_id'] as String,
  patientName: json['patient_name'] as String? ?? '',
  doctorId: json['doctor_id'] as String?,
  doctorName: json['doctor_name'] as String?,
  cabinet: json['cabinet'] as String?,
  service: json['service'] as String?,
  startsAt: json['starts_at'] as String,
  endsAt: json['ends_at'] as String,
  status: json['status'] as String,
  notes: json['notes'] as String?,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$AppointmentToJson(_Appointment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'appointment_no': instance.appointmentNo,
      'branch_id': instance.branchId,
      'patient_id': instance.patientId,
      'patient_name': instance.patientName,
      'doctor_id': instance.doctorId,
      'doctor_name': instance.doctorName,
      'cabinet': instance.cabinet,
      'service': instance.service,
      'starts_at': instance.startsAt,
      'ends_at': instance.endsAt,
      'status': instance.status,
      'notes': instance.notes,
      'created_at': instance.createdAt,
    };
