// «Выручка по дням» — тренд завершённой выручки за последние N локальных дней,
// от старого к новому. PLAIN Dart-классы с ручным fromJson (без freezed/codegen
// — см. AGENTS.md). Зеркалит backend GET /dashboard/revenue-trend?days=14:
//   { "points": [ {"date": "YYYY-MM-DD", "revenue": "<decimal-string>"}, … ] }

/// Одна точка тренда: локальный день (YYYY-MM-DD) и выручка-строка decimal.
class RevenuePoint {
  const RevenuePoint({required this.date, required this.revenue});

  /// Локальная дата в формате `YYYY-MM-DD` (как отдал бэкенд).
  final String date;

  /// Выручка за день — decimal-строка (например `"1250000.00"`).
  final String revenue;

  /// Числовое значение выручки для графика (битый ввод → 0).
  double get revenueValue => double.tryParse(revenue) ?? 0;

  /// Короткая метка `dd.MM` для оси X (из `YYYY-MM-DD`).
  String get dayLabel {
    final parts = date.split('-');
    if (parts.length != 3) return date;
    return '${parts[2]}.${parts[1]}';
  }

  factory RevenuePoint.fromJson(Map<String, dynamic> json) => RevenuePoint(
        date: (json['date'] ?? '').toString(),
        revenue: (json['revenue'] ?? '0').toString(),
      );
}

/// Тренд выручки: список точек в порядке, заданном бэкендом (старые→новые).
class RevenueTrend {
  const RevenueTrend({required this.points});

  /// Ровно `days` точек, от старого дня к новому.
  final List<RevenuePoint> points;

  factory RevenueTrend.fromJson(Map<String, dynamic> json) => RevenueTrend(
        points: ((json['points'] as List<dynamic>?) ?? const [])
            .map((e) => RevenuePoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Нет точек или вся выручка нулевая — показываем «Пока нет выручки».
  bool get isEmpty =>
      points.isEmpty || points.every((p) => p.revenueValue <= 0);
}
