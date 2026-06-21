// Plain Dart models (no Freezed/codegen) mirroring the Super Admin monitoring
// API: системный мониторинг (online / logins / uptime / slow / errors) + sessions.

class OnlineUser {
  OnlineUser({required this.userId, required this.name});
  final String userId;
  final String name;

  factory OnlineUser.fromJson(Map<String, dynamic> j) =>
      OnlineUser(userId: j['user_id'] as String, name: (j['name'] ?? '') as String);
}

class MonitoringStats {
  MonitoringStats({
    required this.uptimeSeconds,
    required this.onlineCount,
    required this.onlineUsers,
    required this.loginsToday,
    required this.totalSessions,
    required this.recentSlow,
    required this.recentErrors,
  });

  final int uptimeSeconds;
  final int onlineCount;
  final List<OnlineUser> onlineUsers;
  final int loginsToday;
  final int totalSessions;
  final List<Map<String, dynamic>> recentSlow;
  final List<Map<String, dynamic>> recentErrors;

  static List<Map<String, dynamic>> _maps(Object? v) => (v as List<dynamic>? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  factory MonitoringStats.fromJson(Map<String, dynamic> j) => MonitoringStats(
        uptimeSeconds: (j['uptime_seconds'] as num).toInt(),
        onlineCount: (j['online_count'] as num).toInt(),
        onlineUsers: (j['online_users'] as List<dynamic>? ?? [])
            .map((e) => OnlineUser.fromJson(e as Map<String, dynamic>))
            .toList(),
        loginsToday: (j['logins_today'] as num).toInt(),
        totalSessions: (j['total_sessions'] as num).toInt(),
        recentSlow: _maps(j['recent_slow']),
        recentErrors: _maps(j['recent_errors']),
      );
}

class SessionRow {
  SessionRow({
    required this.id,
    required this.userId,
    required this.userName,
    required this.startedAt,
    required this.ipAddress,
    required this.userAgent,
    required this.online,
  });

  final String id;
  final String userId;
  final String? userName;
  final String startedAt;
  final String? ipAddress;
  final String? userAgent;
  final bool online;

  factory SessionRow.fromJson(Map<String, dynamic> j) => SessionRow(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        userName: j['user_name'] as String?,
        startedAt: j['started_at'] as String,
        ipAddress: j['ip_address'] as String?,
        userAgent: j['user_agent'] as String?,
        online: (j['online'] ?? false) as bool,
      );
}
