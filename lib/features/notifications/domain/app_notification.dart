// Уведомления — журнал сработавших событий (дефицит склада, инсайты и т.д.).
// PLAIN Dart с ручным fromJson (см. AGENTS.md). Зеркалит backend
// `NotificationOut` (GET /notifications). Журнал доступен только на чтение.

enum NotifKind { stock, insight, reminder, queue, other }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.event,
    required this.channel,
    required this.title,
    this.body,
    required this.status,
    this.refType,
    this.branchId,
    required this.createdAt,
  });

  final String id;
  final String event;
  final String channel;
  final String title;
  final String? body;
  final String status;
  final String? refType;
  final String? branchId;
  final String createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'].toString(),
        event: (json['event'] ?? '').toString(),
        channel: (json['channel'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        body: json['body']?.toString(),
        status: (json['status'] ?? '').toString(),
        refType: json['ref_type']?.toString(),
        branchId: json['branch_id']?.toString(),
        createdAt: (json['created_at'] ?? '').toString(),
      );

  /// Категория по коду события (`low_stock`, `insight_*`, …).
  NotifKind get kind {
    if (event.contains('low_stock') || event.contains('stock')) return NotifKind.stock;
    if (event.startsWith('insight')) return NotifKind.insight;
    if (event.contains('reminder') || event.contains('appointment')) return NotifKind.reminder;
    if (event.contains('queue')) return NotifKind.queue;
    return NotifKind.other;
  }

  String get kindLabel => switch (kind) {
        NotifKind.stock => 'Склад',
        NotifKind.insight => 'Аналитика',
        NotifKind.reminder => 'Напоминание',
        NotifKind.queue => 'Очередь',
        NotifKind.other => 'Событие',
      };
}
