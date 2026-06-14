import 'package:freezed_annotation/freezed_annotation.dart';

part 'queue_ticket.freezed.dart';
part 'queue_ticket.g.dart';

/// Live queue ticket (mirrors backend `QueueTicketOut`).
/// Status flow: waiting → called → serving → done | skipped.
@freezed
abstract class QueueTicket with _$QueueTicket {
  const QueueTicket._();

  const factory QueueTicket({
    required String id,
    required String ticketNumber,
    @Default('doctor') String track,
    required String patientId,
    required String branchId,
    String? visitId,
    String? serviceId,
    String? room,
    required String status,
    @Default(0) int priority,
    String? calledAt,
    String? calledById,
    // Адресная маршрутизация: id специалиста, к кому направлен талон
    // (null = общий пул). Имя резолвится через queueSpecialistsProvider.
    String? assignedUserId,
    required String createdAt,
  }) = _QueueTicket;

  factory QueueTicket.fromJson(Map<String, dynamic> json) =>
      _$QueueTicketFromJson(json);

  bool get isWaiting => status == 'waiting';
  bool get isActive => status == 'called' || status == 'serving';

  String get statusLabel => switch (status) {
        'waiting' => 'ожидает',
        'called' => 'вызван',
        'serving' => 'на приёме',
        'done' => 'завершён',
        'skipped' => 'пропущен',
        _ => status,
      };
}
