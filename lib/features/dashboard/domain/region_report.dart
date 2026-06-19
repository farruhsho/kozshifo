// «Пациенты по регионам» — распределение пациентов по географии привлечения,
// разбитое на новых и посещавших (returning). PLAIN Dart-классы с ручным
// fromJson (без freezed/codegen — см. AGENTS.md).
// Зеркалит backend GET /dashboard/patients-by-region:
//   { "total": int,
//     "regions": [ {"region","new_count","returning_count","total"}, … ] }

/// Один регион: метка, число новых, число посещавших, сумма.
class RegionStat {
  const RegionStat({
    required this.region,
    required this.newCount,
    required this.returningCount,
    required this.total,
  });

  /// Готовая русская метка с бэкенда (`Ферганская`, `Не указано`, …).
  final String region;

  /// Новые пациенты (зарегистрированы / один визит).
  final int newCount;

  /// Посещавшие повторно (>1 визита).
  final int returningCount;

  /// Всего пациентов с этим регионом за период.
  final int total;

  factory RegionStat.fromJson(Map<String, dynamic> json) => RegionStat(
        region: (json['region'] ?? '').toString(),
        newCount: (json['new_count'] as num?)?.toInt() ?? 0,
        returningCount: (json['returning_count'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is RegionStat &&
      other.region == region &&
      other.newCount == newCount &&
      other.returningCount == returningCount &&
      other.total == total;

  @override
  int get hashCode => Object.hash(region, newCount, returningCount, total);
}

/// Отчёт по регионам: суммарно + список (порядок с бэкенда — total desc).
class RegionReport {
  const RegionReport({required this.total, required this.regions});

  /// Сумма по всем регионам (включая «Не указано»).
  final int total;

  /// Регионы в порядке, заданном бэкендом.
  final List<RegionStat> regions;

  factory RegionReport.fromJson(Map<String, dynamic> json) => RegionReport(
        total: (json['total'] as num?)?.toInt() ?? 0,
        regions: ((json['regions'] as List<dynamic>?) ?? const [])
            .map((e) => RegionStat.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Нет данных — показываем «Пока нет данных».
  bool get isEmpty => total == 0;
}
