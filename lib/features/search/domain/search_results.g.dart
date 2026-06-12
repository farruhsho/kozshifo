// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_results.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchPatient _$SearchPatientFromJson(Map<String, dynamic> json) =>
    _SearchPatient(
      id: json['id'] as String,
      mrn: json['mrn'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$SearchPatientToJson(_SearchPatient instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mrn': instance.mrn,
      'full_name': instance.fullName,
      'phone': instance.phone,
    };

_SearchVisit _$SearchVisitFromJson(Map<String, dynamic> json) => _SearchVisit(
  id: json['id'] as String,
  visitNo: json['visit_no'] as String,
  patientId: json['patient_id'] as String,
  patientName: json['patient_name'] as String,
  flowStatus: json['flow_status'] as String? ?? 'registered',
  status: json['status'] as String,
);

Map<String, dynamic> _$SearchVisitToJson(_SearchVisit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'visit_no': instance.visitNo,
      'patient_id': instance.patientId,
      'patient_name': instance.patientName,
      'flow_status': instance.flowStatus,
      'status': instance.status,
    };

_SearchReceipt _$SearchReceiptFromJson(Map<String, dynamic> json) =>
    _SearchReceipt(
      paymentId: json['payment_id'] as String,
      receiptNo: json['receipt_no'] as String,
      amount: json['amount'] as String,
      visitId: json['visit_id'] as String?,
      patientId: json['patient_id'] as String?,
    );

Map<String, dynamic> _$SearchReceiptToJson(_SearchReceipt instance) =>
    <String, dynamic>{
      'payment_id': instance.paymentId,
      'receipt_no': instance.receiptNo,
      'amount': instance.amount,
      'visit_id': instance.visitId,
      'patient_id': instance.patientId,
    };

_SearchResults _$SearchResultsFromJson(Map<String, dynamic> json) =>
    _SearchResults(
      patients:
          (json['patients'] as List<dynamic>?)
              ?.map((e) => SearchPatient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <SearchPatient>[],
      visits:
          (json['visits'] as List<dynamic>?)
              ?.map((e) => SearchVisit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <SearchVisit>[],
      receipts:
          (json['receipts'] as List<dynamic>?)
              ?.map((e) => SearchReceipt.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <SearchReceipt>[],
    );

Map<String, dynamic> _$SearchResultsToJson(_SearchResults instance) =>
    <String, dynamic>{
      'patients': instance.patients.map((e) => e.toJson()).toList(),
      'visits': instance.visits.map((e) => e.toJson()).toList(),
      'receipts': instance.receipts.map((e) => e.toJson()).toList(),
    };
