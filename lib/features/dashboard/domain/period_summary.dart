import 'package:freezed_annotation/freezed_annotation.dart';

part 'period_summary.freezed.dart';
part 'period_summary.g.dart';

/// Заголовочные метрики за выбранный период (mirrors backend `PeriodSummary`).
/// Денежные поля — строки-decimal; счётчики — int. Пересчитывается на лету при
/// смене периода (Сегодня/Вчера/Неделя/Месяц/Квартал/Год/Произвольный).
@freezed
abstract class PeriodSummary with _$PeriodSummary {
  const factory PeriodSummary({
    required String period,
    required String dateFrom,
    required String dateTo,
    required String revenue,
    required String expenses,
    required String profit,
    required int newPatients,
    required int visits,
    required int operations,
    required int diagnostics,
    required int treatments,
  }) = _PeriodSummary;

  factory PeriodSummary.fromJson(Map<String, dynamic> json) =>
      _$PeriodSummaryFromJson(json);
}
