/// Per-direction finance (mirrors backend `FinanceByDirectionReport`). Money
/// fields are decimal strings (formatted with formatMoney). Plain model — no codegen.
class DirectionFinanceRow {
  const DirectionFinanceRow({
    required this.direction,
    required this.label,
    required this.revenue,
    required this.expense,
    required this.profit,
  });

  final String direction;
  final String label;
  final String revenue;
  final String expense;
  final String profit;

  factory DirectionFinanceRow.fromJson(Map<String, dynamic> j) =>
      DirectionFinanceRow(
        direction: j['direction'] as String,
        label: j['label'] as String,
        revenue: j['revenue'].toString(),
        expense: j['expense'].toString(),
        profit: j['profit'].toString(),
      );
}

class FinanceByDirection {
  const FinanceByDirection({
    required this.period,
    required this.rows,
    required this.totalRevenue,
    required this.totalExpense,
    required this.totalProfit,
  });

  final String period;
  final List<DirectionFinanceRow> rows;
  final String totalRevenue;
  final String totalExpense;
  final String totalProfit;

  factory FinanceByDirection.fromJson(Map<String, dynamic> j) => FinanceByDirection(
        period: j['period'] as String,
        rows: [
          for (final e in j['rows'] as List)
            DirectionFinanceRow.fromJson(e as Map<String, dynamic>),
        ],
        totalRevenue: j['total_revenue'].toString(),
        totalExpense: j['total_expense'].toString(),
        totalProfit: j['total_profit'].toString(),
      );
}
