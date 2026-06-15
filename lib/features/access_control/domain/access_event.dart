import 'package:freezed_annotation/freezed_annotation.dart';

part 'access_event.freezed.dart';
part 'access_event.g.dart';

/// A Face ID recognition surfaced in the events feed (mirrors `AccessEventOut`).
@freezed
abstract class AccessEvent with _$AccessEvent {
  const factory AccessEvent({
    required String id,
    required String userId,
    String? userFullName,
    required String direction, // in | out
    required DateTime occurredAt,
    required String source,
  }) = _AccessEvent;

  factory AccessEvent.fromJson(Map<String, dynamic> json) =>
      _$AccessEventFromJson(json);
}
