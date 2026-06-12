import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_results.freezed.dart';
part 'search_results.g.dart';

/// Global smart-search hits (mirror backend `SearchOut`). Sections arrive
/// already filtered by the caller's module permissions.
@freezed
abstract class SearchPatient with _$SearchPatient {
  const factory SearchPatient({
    required String id,
    required String mrn,
    required String fullName,
    String? phone,
  }) = _SearchPatient;

  factory SearchPatient.fromJson(Map<String, dynamic> json) =>
      _$SearchPatientFromJson(json);
}

@freezed
abstract class SearchVisit with _$SearchVisit {
  const factory SearchVisit({
    required String id,
    required String visitNo,
    required String patientId,
    required String patientName,
    @Default('registered') String flowStatus,
    required String status,
  }) = _SearchVisit;

  factory SearchVisit.fromJson(Map<String, dynamic> json) =>
      _$SearchVisitFromJson(json);
}

@freezed
abstract class SearchReceipt with _$SearchReceipt {
  const factory SearchReceipt({
    required String paymentId,
    required String receiptNo,
    required String amount,
    String? visitId,
    String? patientId,
  }) = _SearchReceipt;

  factory SearchReceipt.fromJson(Map<String, dynamic> json) =>
      _$SearchReceiptFromJson(json);
}

@freezed
abstract class SearchResults with _$SearchResults {
  const SearchResults._();

  const factory SearchResults({
    @Default(<SearchPatient>[]) List<SearchPatient> patients,
    @Default(<SearchVisit>[]) List<SearchVisit> visits,
    @Default(<SearchReceipt>[]) List<SearchReceipt> receipts,
  }) = _SearchResults;

  factory SearchResults.fromJson(Map<String, dynamic> json) =>
      _$SearchResultsFromJson(json);

  bool get isEmpty => patients.isEmpty && visits.isEmpty && receipts.isEmpty;
}
