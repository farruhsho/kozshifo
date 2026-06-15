import 'package:freezed_annotation/freezed_annotation.dart';

part 'appointment.freezed.dart';
part 'appointment.g.dart';

/// A booked appointment (mirrors backend `AppointmentOut`).
/// Status flow: booked → arrived → done | cancelled | no_show.
@freezed
abstract class Appointment with _$Appointment {
  const Appointment._();

  const factory Appointment({
    required String id,
    required String appointmentNo,
    required String branchId,
    required String patientId,
    @Default('') String patientName,
    String? doctorId,
    String? doctorName,
    String? cabinet,
    String? service,
    required String startsAt,
    required String endsAt,
    required String status,
    String? notes,
    required String createdAt,
  }) = _Appointment;

  factory Appointment.fromJson(Map<String, dynamic> json) =>
      _$AppointmentFromJson(json);

  /// Local start time (the backend serialises aware-UTC). A naive string is
  /// treated as UTC before converting to local.
  DateTime? get start => _local(startsAt);
  DateTime? get end => _local(endsAt);

  static DateTime? _local(String s) {
    if (s.isEmpty) return null;
    final hasZone = s.endsWith('Z') || RegExp(r'[+-]\d\d:?\d\d$').hasMatch(s);
    return DateTime.tryParse(hasZone ? s : '${s}Z')?.toLocal();
  }

  String get timeLabel {
    final d = start;
    if (d == null) return '';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String get statusLabel => switch (status) {
        'booked' => 'Записан',
        'arrived' => 'Пришёл',
        'done' => 'Принят',
        'cancelled' => 'Отменён',
        'no_show' => 'Не пришёл',
        _ => status,
      };
}
