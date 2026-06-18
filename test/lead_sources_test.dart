// «Источники пациентов» (lead-source analytics):
//  • repository parse — JSON → LeadSourceReport (total + ordered sources)
//    via a fake Dio HttpClientAdapter, plus date-param shaping (YYYY-MM-DD);
//  • widget smoke — the dashboard card renders labels/counts, shows the empty
//    state at zero, and is hidden without `dashboard.view`.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kozshifo/features/auth/application/auth_controller.dart';
import 'package:kozshifo/features/auth/domain/auth_user.dart';
import 'package:kozshifo/features/dashboard/data/dashboard_repository.dart';
import 'package:kozshifo/features/dashboard/domain/dashboard_summary.dart';
import 'package:kozshifo/features/dashboard/domain/insight.dart';
import 'package:kozshifo/features/dashboard/domain/lead_source.dart';
import 'package:kozshifo/features/dashboard/domain/region_report.dart';
import 'package:kozshifo/features/dashboard/domain/revenue_trend.dart';
import 'package:kozshifo/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  // Backend contract: total + sources[] sorted by count desc, all channels
  // present incl. the «Не указан» (unknown) bucket with zeros kept.
  const reportJson = <String, dynamic>{
    'total': 30,
    'sources': [
      {'source': 'instagram', 'label': 'Instagram', 'count': 12},
      {'source': 'recommendation', 'label': 'Рекомендация', 'count': 9},
      {'source': 'unknown', 'label': 'Не указан', 'count': 6},
      {'source': 'telegram', 'label': 'Telegram', 'count': 3},
      {'source': 'billboard', 'label': 'Билборд', 'count': 0},
    ],
  };

  // ─── Model parsing ──────────────────────────────────────────────────────────

  group('LeadSourceReport.fromJson', () {
    test('parses total + sources, preserves labels and order', () {
      final r = LeadSourceReport.fromJson(reportJson);
      expect(r.total, 30);
      expect(r.sources, hasLength(5));
      // Order from the backend is kept verbatim (count desc, zeros last).
      expect(r.sources.map((s) => s.source).toList(),
          ['instagram', 'recommendation', 'unknown', 'telegram', 'billboard']);
      expect(r.sources.first.label, 'Instagram');
      expect(r.sources.first.count, 12);
      // The unknown bucket keeps its «Не указан» label.
      final unknown = r.sources.firstWhere((s) => s.source == 'unknown');
      expect(unknown.label, 'Не указан');
      // Zero channels survive parsing.
      expect(r.sources.last.count, 0);
      expect(r.isEmpty, isFalse);
    });

    test('empty / zero report: total 0 → isEmpty', () {
      final r = LeadSourceReport.fromJson(const {'total': 0, 'sources': []});
      expect(r.total, 0);
      expect(r.sources, isEmpty);
      expect(r.isEmpty, isTrue);
    });

    test('tolerates missing keys with safe defaults', () {
      final r = LeadSourceReport.fromJson(const {});
      expect(r.total, 0);
      expect(r.sources, isEmpty);
    });
  });

  // ─── Repository (fake Dio adapter) ──────────────────────────────────────────

  group('DashboardRepository.leadSources', () {
    (DashboardRepository, RequestOptions Function()) makeRepo() {
      RequestOptions? captured;
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
        ..httpClientAdapter = _CapturingAdapter((options) {
          captured = options;
          return ResponseBody.fromString(
            jsonEncode(reportJson),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        });
      return (DashboardRepository(dio), () => captured!);
    }

    test('parses the wire JSON into a LeadSourceReport', () async {
      final (repo, _) = makeRepo();
      final r = await repo.leadSources();
      expect(r.total, 30);
      expect(r.sources.first.source, 'instagram');
      expect(r.sources.map((s) => s.label), contains('Не указан'));
    });

    test('sends date_from/date_to as date-only strings (no time/Z)', () async {
      final (repo, last) = makeRepo();
      await repo.leadSources(
        from: DateTime(2026, 6, 1),
        to: DateTime(2026, 6, 13),
      );
      final qp = last().queryParameters;
      expect(qp['date_from'], '2026-06-01');
      expect(qp['date_to'], '2026-06-13');
      // Never an ISO timestamp.
      expect(qp['date_from'].toString(), isNot(contains('T')));
      expect(qp['date_to'].toString(), isNot(contains('Z')));
    });

    test('omits date params entirely when no range is given', () async {
      final (repo, last) = makeRepo();
      await repo.leadSources();
      final qp = last().queryParameters;
      expect(qp.containsKey('date_from'), isFalse);
      expect(qp.containsKey('date_to'), isFalse);
    });

    test('maps a backend error to ApiException via .from', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
        ..httpClientAdapter = _CapturingAdapter((_) => ResponseBody.fromString(
              jsonEncode(const {'detail': 'forbidden'}),
              403,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            ));
      await expectLater(
        DashboardRepository(dio).leadSources(),
        throwsA(predicate((e) => e.toString().contains('forbidden'))),
      );
    });
  });

  // ─── Widget: «Источники пациентов» card ─────────────────────────────────────

  // The screen body only renders once the summary FutureProvider resolves, so
  // every widget case stubs summary + insights (we assert on lead sources only).
  List<Override> baseOverrides(AuthUser user) => [
        authControllerProvider.overrideWith(() => _FakeAuth(user)),
        dashboardSummaryProvider.overrideWith((ref) async => _summary),
        insightsProvider.overrideWith((ref) async => const <Insight>[]),
        // The dashboard also renders the «Пациенты по регионам» panel; stub its
        // provider with NON-empty data so it doesn't fire a real Dio call AND
        // doesn't render its own «Пока нет данных» empty state (which would
        // collide with the lead-sources zero-state assertion below).
        patientsByRegionProvider.overrideWith((ref) async => RegionReport.fromJson(const {
              'total': 1,
              'regions': [
                {'region': 'Ферганская', 'new_count': 1, 'returning_count': 0, 'total': 1},
              ],
            })),
        // The dashboard also renders the revenue-trend chart; stub its provider
        // so the screen doesn't fire a real Dio call in widget tests.
        revenueTrendProvider.overrideWith((ref) async => RevenueTrend.fromJson(const {
              'points': [
                {'date': '2026-06-10', 'revenue': '100000'},
                {'date': '2026-06-11', 'revenue': '120000'},
              ],
            })),
      ];

  Widget harness({required List<Override> overrides}) => ProviderScope(
        overrides: overrides,
        // The panel is private; we mount the whole screen but only assert on
        // the lead-sources section it renders.
        child: const MaterialApp(home: DashboardScreen()),
      );

  testWidgets('renders source labels + counts for a director', (tester) async {
    await tester.pumpWidget(harness(overrides: [
      ...baseOverrides(_director),
      leadSourcesProvider.overrideWith(
          (ref) async => LeadSourceReport.fromJson(reportJson)),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Источники пациентов'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('Не указан'), findsOneWidget);
    // Count + percent: 12 of 30 ≈ 40%.
    expect(find.textContaining('40%'), findsOneWidget);
  });

  testWidgets('shows «Пока нет данных» when total is zero', (tester) async {
    await tester.pumpWidget(harness(overrides: [
      ...baseOverrides(_director),
      leadSourcesProvider.overrideWith((ref) async =>
          LeadSourceReport.fromJson(const {'total': 0, 'sources': []})),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Источники пациентов'), findsOneWidget);
    expect(find.text('Пока нет данных'), findsOneWidget);
  });

  testWidgets('hidden for a user without dashboard.view', (tester) async {
    await tester.pumpWidget(harness(overrides: [
      ...baseOverrides(_cashier),
      leadSourcesProvider.overrideWith(
          (ref) async => LeadSourceReport.fromJson(reportJson)),
    ]));
    await tester.pumpAndSettle();

    // No card header, no labels — the section collapses to nothing.
    expect(find.text('Источники пациентов'), findsNothing);
    expect(find.text('Instagram'), findsNothing);
  });
}

// ─── Fixtures / fakes ─────────────────────────────────────────────────────────

const _summary = DashboardSummary(
  revenueToday: '0',
  revenueMonth: '0',
  paymentsToday: 0,
  averageCheckToday: '0',
  visitsToday: 0,
  newPatientsToday: 0,
  patientsTotal: 0,
  queueWaiting: 0,
);

const _director = AuthUser(
  id: 'u-dir',
  email: 'director@kozshifo.uz',
  fullName: 'Директор',
  permissions: ['dashboard.view'],
);

const _cashier = AuthUser(
  id: 'u-cash',
  email: 'kassa@kozshifo.uz',
  fullName: 'Кассир',
  permissions: ['payments.read'],
);

class _FakeAuth extends AuthController {
  _FakeAuth(this._user);

  final AuthUser _user;

  @override
  AuthState build() => AuthState(AuthStatus.authenticated, _user);
}

/// Captures the outgoing RequestOptions and returns a canned response (no net).
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      _handler(options);

  @override
  void close({bool force = false}) {}
}
