// Аналитика — выручка по услуге за месяц. PLAIN Dart с ручным fromJson
// (см. AGENTS.md). Зеркалит backend `TopServiceRow` (/dashboard/top-services).

class TopService {
  const TopService({
    required this.service,
    required this.revenue,
    required this.count,
  });

  final String service;
  final String revenue; // decimal string, e.g. "46800000.00"
  final int count;

  double get revenueValue => double.tryParse(revenue) ?? 0;

  factory TopService.fromJson(Map<String, dynamic> json) => TopService(
        service: (json['service'] ?? '').toString(),
        revenue: (json['revenue'] ?? '0').toString(),
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}
